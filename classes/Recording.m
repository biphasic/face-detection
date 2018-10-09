classdef Recording < handle
    properties
        Eventstream
        EventstreamGrid1
        EventstreamGrid2
        Grids
        IsTrainingRecording
        Center
        Left
        Right
        Parent
    end
    
    methods
        function obj = Recording(eventStream, isTrainingRecording, parent)
            obj.Eventstream = eventStream;
            obj.IsTrainingRecording = isTrainingRecording;
            obj.Center = Blinks(obj, parent);
            obj.Left = Blinks(obj, parent);
            obj.Right = Blinks(obj, parent);
            obj.Grids = cell(1,2);
            obj.Parent = parent;
        end
        
        function locations = getannotatedlocations(obj)
            counter = 0;
            if ~isempty(obj.Center.Location) && ~isempty(obj.Center.Times)
                counter = counter + 1;
                locations{counter} = 'Center';
            end
            if ~isempty(obj.Left.Location) && ~isempty(obj.Left.Times)
                counter = counter + 1;
                locations{counter} = 'Left';
            end
            if ~isempty(obj.Right.Location) && ~isempty(obj.Right.Times)
                counter = counter + 1;
                locations{counter} = 'Right';
            end
            if counter == 0
                error('No blinks have been annotated for this recording')
            end
        end
        
        function [blinksOn, blinksOff] = getallblinks(obj)
            locs = obj.getannotatedlocations;
            for l = 1:numel(locs)
                [blinksOn.(locs{l}), blinksOff.(locs{l})] = obj.(locs{l}).getblinks();
            end
            if isempty(blinksOn)
                error('got no blinks')
            end
        end
        
        function modelblink = getmodelblink(obj, smoothingFactor)
            modelOn = zeros(1,3000);
            modelOff = zeros(1,3000);
            varianceOn = zeros(1,3000);
            varianceOff = zeros(1,3000);
            count = 0;
            if ~isempty(obj.Center.Location) && ~isempty(obj.Center.Times)
                [centerOn, centerOff] = obj.Center.getaverages();
                modelOn = modelOn + centerOn;
                modelOff = modelOff + centerOff;
                count = count + 1;
            end
            if ~isempty(obj.Left.Location) && ~isempty(obj.Left.Times)
                [leftOn, leftOff] = obj.Left.getaverages();
                modelOn = modelOn + leftOn;
                modelOff = modelOff + leftOff;
                count = count + 1;
            end
            if ~isempty(obj.Right.Location) && ~isempty(obj.Right.Times)
                [rightOn, rightOff] = obj.Right.getaverages();
                modelOn = modelOn + rightOn;
                modelOff = modelOff + rightOff;
                count = count + 1;
            end
            if count == 0
                err = MException('MATLAB:UndefinedFunction', "No blink locations set I'm afraid");
                throw(err)
            end
            modelOn = modelOn / count;
            modelOff = modelOff / count;
            count = 0;
            if ~isempty(obj.Center.Location) && ~isempty(obj.Center.Times)
                centerVarianceOn = (centerOn - modelOn).^2;
                varianceOn = varianceOn + centerVarianceOn;
                centerVarianceOff = (centerOff - modelOff).^2;
                varianceOff = varianceOff + centerVarianceOff;
                count = count + 1;
            end
            if ~isempty(obj.Left.Location) && ~isempty(obj.Left.Times)
                leftVarianceOn = (leftOn - modelOn).^2;
                varianceOn = varianceOn + leftVarianceOn;
                leftVarianceOff = (leftOff - modelOff).^2;
                varianceOff = varianceOff + leftVarianceOff;
                count = count + 1;
            end
            if ~isempty(obj.Right.Location) && ~isempty(obj.Right.Times)
                rightVarianceOn = (rightOn - modelOn).^2;
                varianceOn = varianceOn + rightVarianceOn;
                rightVarianceOff = (rightOff - modelOff).^2;
                varianceOff = varianceOff + rightVarianceOff;
                count = count + 1;
            end
            varianceOn = varianceOn / count;
            varianceOff = varianceOff / count;
            
            filterResolution = length(modelOn) / smoothingFactor;
            movingAverageWindow = ones(1, filterResolution)/filterResolution;
            modelblink = Modelblink();
            modelblink.AverageOn = filter(movingAverageWindow, 1, modelOn);
            modelblink.VarianceOn = filter(movingAverageWindow, 1, sqrt(varianceOn));
            modelblink.AverageOff = filter(movingAverageWindow, 1, modelOff);
            modelblink.VarianceOff = filter(movingAverageWindow, 1, sqrt(varianceOff));
        end
        
        function [] = calculatecorrelation(obj)
            tic
            filterOn = obj.Parent.Modelblink.AverageOn;
            filterOff = obj.Parent.Modelblink.AverageOff;
            camera_width = 304;
            camera_height = 240;
            gridScale = 16;
            tile_width = camera_width/gridScale;
            tile_height = camera_height/gridScale;
            c = cell(gridScale);
            c2 = cell(gridScale - 1);
            ts=[];
            x=[];
            y=[];
            p=[];
            corr=[];
            aOn=[];
            aOff=[];

            disp('grid 1')
            for i = 1:gridScale
                for j = 1:gridScale
                    tile = crop_spatial(obj.Eventstream, (i-1) * tile_width, (j-1) * tile_height, tile_width, tile_height);
                    tile = activity(tile, 50000, true);
                    tile = quick_correlation(tile, filterOn, filterOff, obj.Parent.AmplitudeScale, obj.Parent.BlinkLength);
                    c{i,j} = tile;
                    ts = horzcat(ts, tile.ts);
                    x = horzcat(x, ones(1,length(tile.ts)).*((i+0.5) * tile_width));
                    y = horzcat(y, ones(1,length(tile.ts)).*((j+0.5) * tile_height));
                    corr = horzcat(corr, tile.patternCorrelation);
                end
            end
            fusion = [ts; x; y; corr]';
            fusion = sortrows(fusion);
            obj.EventstreamGrid1.ts = fusion(:,1)';
            obj.EventstreamGrid1.x = fusion(:,2)';
            obj.EventstreamGrid1.y = fusion(:,3)';
            obj.EventstreamGrid1.patternCorrelation = fusion(:,4)';
            

            ts=[];
            x=[];
            y=[];
            corr=[];
            aOn=[];
            aOff=[];
            disp('grid 2')
            for i = 1:(gridScale-1)
                for j = 1:(gridScale-1)
                    tile = crop_spatial(obj.Eventstream, (i-1) * tile_width + floor(tile_width/2), (j-1) * tile_height + floor(tile_height/2), tile_width, tile_height);
                    tile = activity(tile, 50000, true);
                    tile = quick_correlation(tile, filterOn, filterOff, obj.Parent.AmplitudeScale, obj.Parent.BlinkLength);
                    c2{i,j} = tile;
                    ts = horzcat(ts, tile.ts);
                    x = horzcat(x, ones(1,length(tile.ts)).*(i * tile_width));
                    y = horzcat(y, ones(1,length(tile.ts)).*(j * tile_height));
                    corr = horzcat(corr, tile.patternCorrelation);
                end
            end
            fusion = [ts; x; y; corr]';
            fusion = sortrows(fusion);
            obj.EventstreamGrid2.ts = fusion(:,1)';
            obj.EventstreamGrid2.x = fusion(:,2)';
            obj.EventstreamGrid2.y = fusion(:,3)';
            obj.EventstreamGrid2.patternCorrelation = fusion(:,4)';
            
            obj.Grids{1,1} = c;
            obj.Grids{1,2} = c2;
            toc
        end
        
        function [] = plotcorrelation(obj, varargin)
            if nargin > 1
                ax = varargin{1};
                %title(varargin{4});
            else
                figure
                ax = gca;
                title([obj.Parent.Name, ', correlation threshold: 0.', int2str(obj.Parent.CorrelationThreshold*100)])
            end
            grid1 = obj.EventstreamGrid1;
            corrThreshold = obj.Parent.CorrelationThreshold;
            scatter3(ax, grid1.x(grid1.patternCorrelation>corrThreshold), -grid1.ts(grid1.patternCorrelation>corrThreshold), grid1.y(grid1.patternCorrelation>corrThreshold))
            hold on
            grid2 = obj.EventstreamGrid2;
            scatter3(ax, grid2.x(grid2.patternCorrelation>corrThreshold), -grid2.ts(grid2.patternCorrelation>corrThreshold), grid2.y(grid2.patternCorrelation>corrThreshold))
            set(gca, 'xtick', [0:19:304])
            set(gca, 'ztick', [0:15:240])
            zlim([0 240])
            xlim([0 304])

            %for e = grid1.ts(grid1.patternCorrelation>corrThreshold)
            maximumDifference = 50000;
            valid = grid1.ts(grid1.patternCorrelation>corrThreshold);
            for e = 2:length(valid)
                %x = abs(grid1.x(grid1.ts == valid(e)) - grid1.x(grid1.ts == valid(e-1)) )/2;
                x1 = grid1.x(grid1.ts == valid(e));
                x2 = grid1.x(grid1.ts == valid(e-1));
                x = (x1(1) + x2(1))/2;
                y = grid1.y(grid1.ts == valid(e));
                y = y(1);
                if valid(e) > 1000000 && (valid(e) - valid(e-1)) < maximumDifference && isequal(grid1.y(grid1.ts == valid(e)), grid1.y(grid1.ts == valid(e-1))) && abs(x1(1) - x2(1)) < 60
                    scatter3(ax, x, -valid(e), y, 'red', 'diamond', 'filled')
                end
            end

            valid = grid2.ts(grid2.patternCorrelation>corrThreshold);
            for e = 2:length(valid)
                %x = abs(grid2.x(grid2.ts == valid(e)) - grid2.x(grid2.ts == valid(e-1)) )/2;
                x1 = grid2.x(grid2.ts == valid(e));
                x2 = grid2.x(grid2.ts == valid(e-1));
                x = (x1(1) + x2(1))/2;
                y = grid2.y(grid2.ts == valid(e));
                y = y(1);
                if valid(e) > 1000000 && (valid(e) - valid(e-1)) < maximumDifference && isequal(grid2.y(grid2.ts == valid(e)), grid2.y(grid2.ts == valid(e-1))) && abs(x1(1) - x2(1)) < 60
                    scatter3(ax, x, -valid(e), y, 'red', 'diamond', 'filled')
                end
            end
        end
        
        function [] = plottileactivity(obj, grid, x, y)
            if isempty(obj.Grids{grid})
                error('Grid is empty, have you run the correlation ?')
            end
            eye = obj.Grids{grid}{x,y};
            eye = quick_correlation(eye, obj.Parent.Modelblink.AverageOn, obj.Parent.Modelblink.AverageOff, obj.Parent.AmplitudeScale, obj.Parent.BlinkLength);
            timeScale = 10;
            continuum = shannonise(eye, timeScale);
            correlationThreshold = obj.Parent.CorrelationThreshold;
            figure 
            %plot([0 eye.ts(end)], [correlationThreshold correlationThreshold]);
            hold on;
            ylim([0 10])
            xlim([0 eye.ts(end)])
            opts1={'FaceAlpha', 0.7, 'FaceColor', [0    0.4470    0.7410]};%blau
            opts2={'FaceAlpha', 0.7, 'FaceColor', [0.8500    0.3250    0.0980]};%rot
            
            windows = eye.ts(~isnan(eye.patternCorrelation));
            disp(['Number of windows: ', num2str(length(windows))])
            for i=eye.ts(~isnan(eye.patternCorrelation))
                a = area([i-obj.Parent.BlinkLength i], [max(eye.patternCorrelation(eye.ts == i)) max(eye.patternCorrelation(eye.ts == i))]);
                a.FaceAlpha = 0.1;
                if eye.patternCorrelation(eye.ts == i) > correlationThreshold
                    a.FaceColor = 'yellow';
                    a.FaceAlpha = 0.5;
                end
            end
            z = zeros(1, numel(continuum.activityOn));
            x = continuum.ts *timeScale;
            y1 = continuum.activityOff / obj.Parent.AmplitudeScale;
            y2 = continuum.activityOn / obj.Parent.AmplitudeScale;
            fill_between(x, y1, y2, y1 < y2, opts2{:});
            fill_between(x, z, y1, y1 > z, opts1{:});
            %sometimes it is desired to rather show the events 
            %stem(eye.ts, eye.activityOn/subjects.(names{s}).AmplitudeScale);
            %stem(eye.ts, -eye.activityOff/subjects.(names{s}).AmplitudeScale);
        end

    end

end