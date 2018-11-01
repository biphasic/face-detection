classdef Blinklocation
    properties
        Location
        Times
        Parent
        AmplitudeScaleScale = 1
    end
    
    methods
        function obj = Blinklocation(parent)
            obj.Parent = parent;
        end
        
        %return all the blinks for one location
        function [blinksOn, blinksOff] = getblinks(obj)
            if ~isempty(obj.Location) && ~isempty(obj.Times)
                tileWidth = obj.Parent.TileSizes(1);
                tileHeight = obj.Parent.TileSizes(2);
                eye = crop_spatial(obj.Parent.Eventstream, obj.Location(1)-tileWidth/2, obj.Location(2)-tileHeight/2, tileWidth, tileHeight);
                eye = activity(eye, obj.Parent.Parent.ActivityDecayConstant, (1 / obj.Parent.Parent.AmplitudeScale) * obj.AmplitudeScaleScale);
                eye = shannonise(eye, obj.Parent.Parent.ActivityDecayConstant, obj.Parent.Parent.ModelSubsamplingRate);
                blinkRow = obj.Times;
                blinklength = obj.Parent.Parent.BlinkLength;
                blinksOn = zeros(nnz(obj.Times), blinklength/obj.Parent.Parent.ModelSubsamplingRate);
                blinksOff = blinksOn;
                for i = 1:nnz(blinkRow)
                    indexes = eye.ts >= blinkRow(i) & eye.ts < (blinkRow(i)+blinklength);
                    blinksOn(i,:) = eye.activityOn(indexes);
                    blinksOff(i,:) = eye.activityOff(indexes);
                end
            else
                error('no blinks saved for this location');
            end
        end
        
        function blinks = getblinkevents(obj)
            tileWidth = obj.Parent.TileSizes(1);
            tileHeight = obj.Parent.TileSizes(2);
            eye = crop_spatial(obj.Parent.Eventstream, obj.Location(1)-tileWidth/2, obj.Location(2)-tileHeight/2, tileWidth, tileHeight);
            blinkRow = obj.Times;
            %blinks = nan(1, nnz(blinkRow));
            for i = 1:nnz(blinkRow)
                indexes = eye.ts >= blinkRow(i) & eye.ts < (blinkRow(i)+obj.Parent.Parent.BlinkLength);
                blinks(i).ts = eye.ts(indexes);
                blinks(i).x = eye.x(indexes);
                blinks(i).y = eye.y(indexes);
                blinks(i).p = eye.p(indexes);
            end
        end

        %return an average model blink for one location
        function [averageOn, averageOff] = getaverages(obj)
            [averageOn, averageOff] = obj.getblinks();
            if size(averageOn, 1) ~= 1
                averageOn = sum(averageOn) / size(averageOn, 1);
                averageOff = sum(averageOff) / size(averageOff, 1);
            end
        end
        
        function plotblinks(obj, varargin)
            if numel(varargin) > 0
                ax = varargin{1};
            else
                figure
                ax = gca;
            end
            hold on
            [blinksOn, blinksOff] = obj.getblinks;
            for n = 1:size(blinksOn, 1)
                plot(ax, blinksOn(n, :), 'red')
                plot(ax, blinksOff(n, :), 'blue')
            end
        end
        
        function plotactivity(obj, varargin)
            if isempty(obj.Times) || isempty(obj.Location)
                error('No blinks annotated for this location.')
            end
            if nargin > 1
                row = varargin{1};
                column = varargin{2};
                pos = varargin{3};
                subplot(row, column, pos)
                title(varargin{4});
            else
                figure
            end
            hold on;
            tileWidth = obj.Parent.TileSizes(1);
            tileHeight = obj.Parent.TileSizes(2);
            eye = crop_spatial(obj.Parent.Eventstream, obj.Location(1)-tileWidth/2, obj.Location(2)-tileHeight/2, tileWidth, tileHeight);
            eye = activity(eye, obj.Parent.Parent.ActivityDecayConstant, (1 / obj.Parent.Parent.AmplitudeScale) * obj.AmplitudeScaleScale);
            eye = quick_correlation(eye, obj.Parent.Parent.Modelblink.AverageOn, obj.Parent.Parent.Modelblink.AverageOff, obj.Parent.Parent.AmplitudeScale / obj.AmplitudeScaleScale, obj.Parent.Parent.BlinkLength, obj.Parent.Parent.ModelSubsamplingRate);
            continuum = shannonise(eye, obj.Parent.Parent.ActivityDecayConstant, obj.Parent.Parent.ModelSubsamplingRate);
            correlationThreshold = obj.Parent.Parent.CorrelationThreshold;
            ylim([0 4])
            xlim([0 obj.Times(end)+8000000])
            %xt=arrayfun(@num2str,get(gca,'xtick')*0.000001, 'UniformOutput', false);
            %set(gca,'xticklabel',xt)
            windows = eye.ts(~isnan(eye.patternCorrelation));
            if nargin > 3
                disp(['Number of windows: ', num2str(length(windows)), ' for ', varargin{4}])
            else
                disp(['Number of windows: ', num2str(length(windows))])
            end
            for i=eye.ts(and(~isnan(eye.patternCorrelation), eye.ts<(obj.Times(end)+8000000)))
                a = area([i-obj.Parent.Parent.BlinkLength i], [max(eye.patternCorrelation(eye.ts == i)) max(eye.patternCorrelation(eye.ts == i))]);
                a.FaceAlpha = 0.1;
                if eye.patternCorrelation(eye.ts == i) > correlationThreshold
                    a.FaceColor = 'yellow';
                    a.FaceAlpha = 0.5;
                end
            end
            for i = obj.Times
                a = area([i i+obj.Parent.Parent.BlinkLength], [4 4]);
                a.FaceAlpha = 0.1;
                a.FaceColor = 'green';
            end
            mask = and(continuum.ts > ((obj.Times(1)-8000000)), continuum.ts < ((obj.Times(end)+8000000)));
            z = zeros(1, length(continuum.activityOn(mask)));
            x = continuum.ts(mask);
            y1 = continuum.activityOn(mask);
            y2 = continuum.activityOff(mask);
            opts1={'FaceAlpha', 0.7, 'FaceColor', obj.Parent.Parent.Parent.OnColour};%rot
            opts2={'FaceAlpha', 0.7, 'FaceColor', obj.Parent.Parent.Parent.OffColour};%blau
            fill_between(x, y2, y1, y2 < y1, opts1{:});
            fill_between(x, z, y2, y2 > z, opts2{:});
            %sometimes it is desired to rather show the events 
            %stem(eye.ts, eye.activityOn/subjects.(names{s}).AmplitudeScale);
            %stem(eye.ts, -eye.activityOff/subjects.(names{s}).AmplitudeScale);
            path = '/home/gregorlenz/Recordings/face-detection/indoor/printing-with-matplotlib/activity-detail.csv';
            times = zeros(1, length(y2));
            times(1:length(obj.Times)) = obj.Times;
            m = [x; y1; y2; times];
            csvwrite(path, m);
        end
        
        function plotmodelversusevents(obj, blinknumber)
            close all
            figure
            model = obj.Parent.Parent.Modelblink;
            events = obj.getblinkevents;
            events = activity(events(blinknumber), 50000, 1/obj.Parent.Parent.AmplitudeScale, true);
            z = zeros(1, length(model.AverageOff));
            opts={'FaceAlpha', 0.1, 'FaceColor', 'black', 'DisplayName', 'continuous model'};
            scale = 1;
            
            ax = subplot(2,15,21:24);
            subplot(2,15,30)
            subplot(2,15,26:29)
            
            %%%%%%third
            [line1, line2, patch] = fill_between(1:length(model.AverageOff), z, model.AverageOff*scale, model.AverageOff > z, opts{:});
            line1.delete;
            line2.delete;
            patch.EdgeAlpha = 0;
            hold on
            divisor = events.ts(end) - obj.Parent.Parent.BlinkLength;
            for i = 1:length(events.ts)
                index = ceil(mod(events.ts(i), divisor)/100);
                if index == 0
                    index = 1;
                end
                z(index) = events.activityOff(i);
            end
            intersect(z > 0) = model.AverageOff(z > 0)*scale;
            intersect(intersect == 0) = nan;
            stem(intersect, ':k', 'filled', 'DisplayName', 'sparse model');
            z(z==0) = nan;
            h = stem(z, ':^b', 'filled', 'DisplayName', 'activity of events received');
            xticklabels('')
            xlabel('250ms')
            ylabel('normalised activity')
            %legend('Location', 'south')
            
            a = area([0 1], [0.92 0.92]);
            a.FaceAlpha = 0.6;
            a.FaceColor = 'green';
            xticklabels('')
            xticks([0 1])
            ylabel('correlation score')
            ylim([0 1])
            
            %%twooooo
            z = zeros(1, length(model.AverageOff));
            [line1, line2, patch] = fill_between(1:length(model.AverageOff), z, model.AverageOff*scale, model.AverageOff > z, opts{:});
            line1.delete;
            line2.delete;
            patch.EdgeAlpha = 0;
            z = [zeros(1, 718), z(1:1782)];
            intersect = zeros(1,length(z));
            intersect(z > 0) = model.AverageOff(z > 0)*scale;
            intersect(intersect == 0) = nan;
            stem(ax, intersect, ':k', 'filled', 'DisplayName', 'sparse model');
            z(z==0) = nan;
            h = stem(ax, z, ':^b', 'filled', 'DisplayName', 'activity of events received');
            xticklabels('')
            xlabel('250ms')
            ylabel('normalised activity')
            %legend('Location', 'northwest')
            
            subplot(2,15,25)
            a = area([0 1], [0.52 0.52]);
            a.FaceAlpha = 0.6;
            a.FaceColor = 'yellow';
            xticklabels('')
            xticks([0 1])
            ylabel('correlation score')
            ylim([0 1])
            
            %%%%%%%%%%%%first
            subplot(2,15,16:19)
            tileWidth = obj.Parent.TileSizes(1);
            tileHeight = obj.Parent.TileSizes(2);
            eye = crop_spatial(obj.Parent.Eventstream, obj.Location(1)-tileWidth/2, obj.Location(2)-tileHeight/2, tileWidth, tileHeight);
            eye = activity(eye, obj.Parent.Parent.ActivityDecayConstant, (1 / obj.Parent.Parent.AmplitudeScale) * obj.AmplitudeScaleScale);
            z = zeros(1, length(model.AverageOff));
            [line1, line2, patch] = fill_between(1:length(model.AverageOff), z, model.AverageOff*scale, model.AverageOff > z, opts{:});
            line1.delete;
            line2.delete;
            patch.EdgeAlpha = 0;
            hold on
            divisor = events.ts(end) - obj.Parent.Parent.BlinkLength;
            for i = 1:length(events.ts)
                index = ceil(mod(events.ts(i), divisor)/100);
                if index == 0
                    index = 1;
                end
                z(index) = events.activityOff(i);
            end
            z = [zeros(1, 718), z(1:1782)];
            intersect = zeros(1,length(z));
            intersect(z > 0) = model.AverageOff(z > 0)*scale;
            intersect(intersect == 0) = nan;
            stem(intersect, ':k', 'filled', 'DisplayName', 'sparse model');
            z(z==0) = nan;
            h = stem(z, ':^b', 'filled', 'DisplayName', 'activity of events received');
            xticklabels('')
            xlabel('250ms')
            ylabel('normalised activity')
            %legend('Location', 'northwest')
            
            subplot(2,15,20)
            a = area([0 1], [0.52 0.52]);
            a.FaceAlpha = 0.6;
            a.FaceColor = 'yellow';
            xticklabels('')
            xticks([0 1])
            ylabel('correlation score')
            ylim([0 1])
        end
        
    end
end

