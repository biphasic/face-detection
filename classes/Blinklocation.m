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
                plot(ax, blinksOn(n, :)/obj.Parent.Parent.AmplitudeScale, 'red')
                plot(ax, blinksOff(n, :)/obj.Parent.Parent.AmplitudeScale, 'blue')
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
            eye = quick_correlation(eye, obj.Parent.Parent.Modelblink.AverageOn, obj.Parent.Parent.Modelblink.AverageOff, obj.Parent.Parent.AmplitudeScale, obj.Parent.Parent.BlinkLength, obj.Parent.Parent.ModelSubsamplingRate);
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
            y1 = continuum.activityOff(mask);
            y2 = continuum.activityOn(mask);
            %fxOff = [x, fliplr(x)];
            %foff = [z, fliplr(y1)];
            %mask = y2 > y1;
            %fxOn = [x(mask), fliplr(x(mask))];
            %fOn = [y1(mask), fliplr(y2(mask))];
            %fill(fxOff, foff, [0    0.4470    0.7410], 'FaceAlpha', 0.7); % blue
            %fill(fxOn, fOn, [0.8500    0.3250    0.0980], 'FaceAlpha', 0.7); % red
            opts1={'FaceAlpha', 0.7, 'FaceColor', [0    0.4470    0.7410]};%blau
            opts2={'FaceAlpha', 0.7, 'FaceColor', [0.8500    0.3250    0.0980]};%rot
            fill_between(x, y1, y2, y1 < y2, opts2{:});
            fill_between(x, z, y1, y1 > z, opts1{:});
            %sometimes it is desired to rather show the events 
            %stem(eye.ts, eye.activityOn/subjects.(names{s}).AmplitudeScale);
            %stem(eye.ts, -eye.activityOff/subjects.(names{s}).AmplitudeScale);
        end
    end
end

