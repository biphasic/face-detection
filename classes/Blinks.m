classdef Blinks
    properties
        Location
        Times
        Parent
        GrandParent
    end
    
    methods
        function obj = Blinks(parent, grandparent)
            obj.Parent = parent;
            obj.GrandParent = grandparent;
        end
        
        %return all the blinks for one location
        function [blinksOn, blinksOff] = getblinks(obj)
            if ~isempty(obj.Location) && ~isempty(obj.Times)
                tileWidth = 19;
                tileHeight = 15;
                eye = crop_spatial(obj.Parent.Eventstream, obj.Location(1)-tileWidth/2, obj.Location(2)-tileHeight/2, tileWidth, tileHeight);
                eye = activity(eye, 50000, true);
                scaleFactor = 10;
                eye = shannonise(eye, scaleFactor);
                blinkRow = obj.Times / scaleFactor;
                blinklength = obj.GrandParent.BlinkLength / scaleFactor;
                blinksOn = zeros(nnz(obj.Times), blinklength/ scaleFactor);
                blinksOff = blinksOn;
                
                for i = 1:nnz(blinkRow)
                    indexes = eye.ts >= blinkRow(i) & eye.ts < (blinkRow(i)+blinklength);
                    % normalise over number of blinkRow and a normalising
                    % factor that is specific for each subject
                    blinksOn(i,:) = eye.activityOn(indexes) / obj.GrandParent.AmplitudeScale;
                    blinksOff(i,:) = eye.activityOff(indexes) / obj.GrandParent.AmplitudeScale;
                end
            else
                error('no blinks saved for this location');
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
        
        function [] = plotactivity(obj, varargin)
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
            tileWidth = 19;
            tileHeight = 15;
            eye = crop_spatial(obj.Parent.Eventstream, obj.Location(1)-tileWidth/2, obj.Location(2)-tileHeight/2, tileWidth, tileHeight);
            eye = activity(eye, 50000, true);
            eye = quick_correlation(eye, obj.GrandParent.Modelblink.AverageOn, obj.GrandParent.Modelblink.AverageOff, obj.GrandParent.AmplitudeScale, obj.GrandParent.BlinkLength);
            timeScale = 10;
            continuum = shannonise(eye, timeScale);
            correlationThreshold = obj.GrandParent.CorrelationThreshold;
            %plot([0 eye.ts(end)], [correlationThreshold correlationThreshold]);
            %p = plot(continuum.ts*timeScale, continuum.activityOn/obj.GrandParent.AmplitudeScale);
            %p.Color = [0    0.4470    0.7410];
            %p = plot(continuum.ts*timeScale, continuum.activityOff/obj.GrandParent.AmplitudeScale);
            %p.Color = [0.8500    0.3250    0.0980];
            %title(ax, loc)
            ylim([0 4])
            xlim([0 obj.Times(end)+8000000])
            %xt=arrayfun(@num2str,get(gca,'xtick')*0.000001, 'UniformOutput', false);
            %set(gca,'xticklabel',xt)
            opts1={'FaceAlpha', 0.7, 'FaceColor', [0    0.4470    0.7410]};%blau
            opts2={'FaceAlpha', 0.7, 'FaceColor', [0.8500    0.3250    0.0980]};%rot
            
            windows = eye.ts(~isnan(eye.patternCorrelation));
            if nargin > 3
                disp(['Number of windows: ', num2str(length(windows)), ' for ', varargin{4}])
            else
                disp(['Number of windows: ', num2str(length(windows))])
            end
            for i=eye.ts(and(~isnan(eye.patternCorrelation), eye.ts<(obj.Times(end)+8000000)))
                a = area([i-obj.GrandParent.BlinkLength i], [max(eye.patternCorrelation(eye.ts == i)) max(eye.patternCorrelation(eye.ts == i))]);
                a.FaceAlpha = 0.1;
                if eye.patternCorrelation(eye.ts == i) > correlationThreshold
                    a.FaceColor = 'yellow';
                    a.FaceAlpha = 0.5;
                end
            end
            for i = obj.Times
                a = area([i i+obj.GrandParent.BlinkLength], [4 4]);
                a.FaceAlpha = 0.1;
                a.FaceColor = 'green';
            end
            mask = and(continuum.ts > ((obj.Times(1)-8000000)/timeScale), continuum.ts < ((obj.Times(end)+8000000)/timeScale));
            z = zeros(1, numel(continuum.activityOn(mask)));
            x = continuum.ts(mask)*timeScale;
            y1 = continuum.activityOff(mask)/obj.GrandParent.AmplitudeScale;
            y2 = continuum.activityOn(mask)/obj.GrandParent.AmplitudeScale;
            fill_between(x, y1, y2, y1 < y2, opts2{:});
            fill_between(x, z, y1, y1 > z, opts1{:});
            %sometimes it is desired to rather show the events 
            %stem(eye.ts, eye.activityOn/subjects.(names{s}).AmplitudeScale);
            %stem(eye.ts, -eye.activityOff/subjects.(names{s}).AmplitudeScale);
        end
    end
end

