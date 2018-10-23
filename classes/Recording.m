classdef Recording < handle
    properties
        Number
        Eventstream
        EventstreamGrid1
        EventstreamGrid2
        Grids = cell(1,2)
        IsTrainingRecording
        Center
        Left
        Right
        Dimensions = [304, 240]
        GridSizes = [16, 16]
        Parent
    end
    properties (Dependent)
        TileSizes
    end
    
    methods
        function obj = Recording(number, eventStream, isTrainingRecording, parent)
            obj.Number = number;
            obj.Eventstream = eventStream;
            obj.IsTrainingRecording = isTrainingRecording;
            obj.Center = Blinks(obj, parent);
            obj.Left = Blinks(obj, parent);
            obj.Right = Blinks(obj, parent);
            obj.Parent = parent;
        end
        
        function tilesizes = get.TileSizes(obj)
            tilesizes = obj.Dimensions ./ obj.GridSizes;
        end
        function set.GridSizes(obj, sizes)
            if mod(obj.Dimensions, sizes) ~= 0
                error('grid size does not align well with dimensions of the recording')
            end
            obj.GridSizes = sizes;
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
            size = obj.Parent.BlinkLength/obj.Parent.ModelSubsamplingRate;
            modelOn = zeros(1, size);
            modelOff = zeros(1, size);
            varianceOn = zeros(1, size);
            varianceOff = zeros(1, size);
            locs = obj.getannotatedlocations;
            for l = 1:numel(locs)
                [averageOn, averageOff] = obj.(locs{l}).getaverages();
                modelOn = modelOn + averageOn/numel(locs);
                modelOff = modelOff + averageOff/numel(locs);
            end
            for l = 1:numel(locs)
                [averageOn, averageOff] = obj.(locs{l}).getaverages();
                varianceOn = varianceOn + (averageOn - modelOn).^2/numel(locs);
                varianceOff = varianceOff + (averageOff - modelOff).^2/numel(locs);
            end
            filterResolution = floor(length(modelOn) / smoothingFactor);
            movingAverageWindow = ones(1, filterResolution)/filterResolution;
            modelblink = Modelblink();
            amplitudescale = floor(max(filter(movingAverageWindow, 1, modelOn)));
            if obj.Parent.AmplitudeScale ~= amplitudescale
                obj.Parent.AmplitudeScale = amplitudescale;
                disp(['Amplitude scale: ', int2str(amplitudescale)])
            end
            modelblink.AverageOn = filter(movingAverageWindow/amplitudescale, 1, modelOn);
            modelblink.VarianceOn = filter(movingAverageWindow/amplitudescale, 1, sqrt(varianceOn));
            modelblink.AverageOff = filter(movingAverageWindow/amplitudescale, 1, modelOff);
            modelblink.VarianceOff = filter(movingAverageWindow/amplitudescale, 1, sqrt(varianceOff));
        end
        
        function calculatecorrelation(obj)
            tic
            tile_width = obj.TileSizes(1);
            tile_height = obj.TileSizes(2);
            c = cell(obj.GridSizes(1), obj.GridSizes(2));
            c2 = cell(obj.GridSizes(1)-1, obj.GridSizes(2)-1);
            
            ts=[];
            x=[];
            y=[];
            corr=[];
            disp('grid 1')
            for i = 1:obj.GridSizes(1)
                for j = 1:obj.GridSizes(2)
                    tile = crop_spatial(obj.Eventstream, (i-1) * tile_width, (j-1) * tile_height, tile_width, tile_height);
                    tile = activity(tile, obj.Parent.ActivityDecayConstant, true);
                    tile = quick_correlation(tile, obj.Parent.Modelblink.AverageOn, obj.Parent.Modelblink.AverageOff, obj.Parent.AmplitudeScale, obj.Parent.BlinkLength, obj.Parent.ModelSubsamplingRate);
                    c{i,j} = tile;
                    ts = horzcat(ts, tile.ts);
                    x = horzcat(x, ones(1,length(tile.ts)).*((i-0.5) * (tile_width)));
                    y = horzcat(y, ones(1,length(tile.ts)).*((j-0.5) * (tile_height)));
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
            disp('grid 2')
            for i = 1:(obj.GridSizes(1)-1)
                for j = 1:(obj.GridSizes(2)-1)
                    tile = crop_spatial(obj.Eventstream, (i-1) * tile_width + floor(tile_width/2), (j-1) * tile_height + floor(tile_height/2), tile_width, tile_height);
                    tile = activity(tile, obj.Parent.ActivityDecayConstant, true);
                    tile = quick_correlation(tile, obj.Parent.Modelblink.AverageOn, obj.Parent.Modelblink.AverageOff, obj.Parent.AmplitudeScale, obj.Parent.BlinkLength, obj.Parent.ModelSubsamplingRate);
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
        
        function plotcorrelation(obj, varargin)
            if isempty(obj.EventstreamGrid1)
                error('No data present')
            end
            if nargin > 1
                ax = varargin{1};
            else
                figure;
                ax = gca;
            end
            grid1 = obj.EventstreamGrid1;
            corrThreshold = obj.Parent.CorrelationThreshold;
            scatter3(ax, grid1.x(grid1.patternCorrelation>corrThreshold), -grid1.ts(grid1.patternCorrelation>corrThreshold), grid1.y(grid1.patternCorrelation>corrThreshold))
            grid2 = obj.EventstreamGrid2;
            hold on
            scatter3(ax, grid2.x(grid2.patternCorrelation>corrThreshold), -grid2.ts(grid2.patternCorrelation>corrThreshold), grid2.y(grid2.patternCorrelation>corrThreshold))
            set(gca, 'xtick', 0:obj.TileSizes(1):obj.Dimensions(1))
            set(gca, 'ztick', 0:obj.TileSizes(2):obj.Dimensions(2))
            xt=arrayfun(@num2str,get(gca,'xtick')/obj.TileSizes(1), 'UniformOutput', false);
            zt=arrayfun(@num2str,get(gca,'ztick')/obj.TileSizes(2), 'UniformOutput', false);
            set(gca,'xticklabel',xt)
            set(gca,'zticklabel',zt)
            zlim([0 obj.Dimensions(2)])
            xlim([0 obj.Dimensions(1)])

            maximumDifference = 50000;
            valid = grid1.ts(grid1.patternCorrelation>corrThreshold);
            for e = 2:length(valid)
                %x = abs(grid1.x(grid1.ts == valid(e)) - grid1.x(grid1.ts == valid(e-1)) )/2;
                x1 = grid1.x(grid1.ts == valid(e));
                x2 = grid1.x(grid1.ts == valid(e-1));
                x = (x1(1) + x2(1))/2;
                y = grid1.y(grid1.ts == valid(e));
                y = y(1);
                if valid(e) > 700000 && (valid(e) - valid(e-1)) < maximumDifference && isequal(grid1.y(grid1.ts == valid(e)), grid1.y(grid1.ts == valid(e-1))) && abs(x1(1) - x2(1)) < 60 && x1(1) ~= x2(1)
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
                if valid(e) > 700000 && (valid(e) - valid(e-1)) < maximumDifference && isequal(grid2.y(grid2.ts == valid(e)), grid2.y(grid2.ts == valid(e-1))) && abs(x1(1) - x2(1)) < 60 && x1(1) ~= x2(1)
                    scatter3(ax, x, -valid(e), y, 'red', 'diamond', 'filled')
                end
            end
            
            title([obj.Parent.Name, ' rec No. ', int2str(obj.Number), ', corr threshold: 0.', int2str(obj.Parent.CorrelationThreshold*100), ', model temporal resolution: ', int2str(obj.Parent.ModelSubsamplingRate), 'us'])
        end
        
        function plottileactivity(obj, grid, x, y)
            if isempty(obj.Grids{grid})
                error('Grid is empty, have you run the correlation ?')
            end
            eye = obj.Grids{grid}{x,y};
            eye = quick_correlation(eye, obj.Parent.Modelblink.AverageOn, obj.Parent.Modelblink.AverageOff, obj.Parent.AmplitudeScale, obj.Parent.BlinkLength, obj.Parent.ModelSubsamplingRate);
            continuum = shannonise(eye, obj.Parent.ActivityDecayConstant, obj.Parent.ModelSubsamplingRate);
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
            z = zeros(1, length(continuum.activityOn));
            x = continuum.ts;
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