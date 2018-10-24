classdef Recording < handle
    properties
        Number
        Eventstream
        Blinks = []
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
            obj.Center = Blinklocation(obj, parent);
            obj.Left = Blinklocation(obj, parent);
            obj.Right = Blinklocation(obj, parent);
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
        
        function calculatetracking(obj)
            for i = 1:length(obj.Eventstream)

            end
        end
        
        function detectblinks(obj)
            if isempty(obj.EventstreamGrid1)
                error('No data present')
            end
            obj.Blinks = Blink(1,1,1,1,1);
            blinkIndex = 1;
            combinedGrid = merge_streams(obj.EventstreamGrid1, obj.EventstreamGrid2);
            mask = combinedGrid.patternCorrelation>obj.Parent.CorrelationThreshold;
            
            maximumDifference = 50000;
            tileWidth = obj.TileSizes(1);
            tileHeight = obj.TileSizes(2);
            indices = find(mask);
            for i = 4:length(indices)
                %last three events are close enough in time and do not have
                %the same x value
                if combinedGrid.ts(indices(i)) - combinedGrid.ts(indices(i-2)) < maximumDifference && ~isequal(combinedGrid.x(indices(i)), combinedGrid.x(indices(i-1))) && ~isequal(combinedGrid.x(indices(i)), combinedGrid.x(indices(i-2))) && ~isequal(combinedGrid.x(indices(i-1)), combinedGrid.x(indices(i-2)))%check temporal coherence
                    %last 4 events are close enough in time and have the
                    %same x value
                    if combinedGrid.ts(indices(i)) - combinedGrid.ts(indices(i-3)) < maximumDifference && ~isequal(combinedGrid.x(indices(i)), combinedGrid.x(indices(i-3))) && ~isequal(combinedGrid.x(indices(i-1)), combinedGrid.x(indices(i-3))) && ~isequal(combinedGrid.x(indices(i-2)), combinedGrid.x(indices(i-3)) )
                        for row = 1:4
                            quadruplet(row,:) = [combinedGrid.x(indices(i-(row-1))), combinedGrid.y(indices(i-(row-1)))];
                        end
                        quadruplet = sortrows(quadruplet);
                        leftDelta = abs(quadruplet(2,:) - quadruplet(1,:));
                        leftMean = (quadruplet(2,:) + quadruplet(1,:))/2;
                        right = abs(quadruplet(4,:) - quadruplet(3,:));
                        rightMean = (quadruplet(4,:) + quadruplet(3,:))/2;
                        diff = (rightMean - leftMean);
                        if leftDelta(1) < tileWidth && leftDelta(2) < tileHeight && right(1) < tileWidth && right(2) < tileHeight && diff(1) > tileWidth && diff(1) < 50 && diff(2) < tileHeight
                            obj.Blinks(blinkIndex) = Blink(leftMean(1), leftMean(2), rightMean(1), rightMean(2), combinedGrid.ts(indices(i)));
                            blinkIndex = blinkIndex + 1;
                            continue;
                        end
                    end
                    %last three events, either two on the left or two on
                    %the right
                    for row = 1:3
                        triplet(row,:) = [combinedGrid.x(indices(i-(row-1))), combinedGrid.y(indices(i-(row-1)))];
                    end
                    triplet = sortrows(triplet);
                    %two on the left
                    leftDiff = abs(triplet(2,:) - triplet(1,:));
                    leftMean = ((triplet(2,:) + triplet(1,:))/2);
                    if  leftDiff(1) < tileWidth && leftDiff(2) < tileHeight && triplet(3,1) - leftMean(1) > tileWidth && triplet(3,1) - leftMean(1) < 50 && abs(triplet(3,2) - leftMean(2)) < tileHeight
                        obj.Blinks(blinkIndex) = Blink(leftMean(1), leftMean(2), triplet(3,1), leftMean(2), combinedGrid.ts(indices(i)));
                        blinkIndex = blinkIndex + 1;
                    end
                    %two on the right
                    rightDiff = abs(triplet(3,:) - triplet(2,:));
                    rightMean = ((triplet(3,:) + triplet(2,:))/2);
                    if  rightDiff(1) < tileWidth && rightDiff(2) < tileHeight && rightMean(1) - triplet(1,1) > tileWidth && rightMean(1) - triplet(1,1) < 50 && abs(triplet(1,2) - rightMean(2)) < tileHeight
                        obj.Blinks(blinkIndex) = Blink(triplet(1,1), rightMean(2), rightMean(1), rightMean(2), combinedGrid.ts(indices(i)));
                        blinkIndex = blinkIndex + 1;
                    end
                end
            end
        end
        
        function plotblinks(obj, varargin)
            if isempty(obj.EventstreamGrid1)
                error('No data present')
            end
            if nargin > 1
                ax = varargin{1};
            else
                figure;
                ax = gca;
            end
            for i = 1:length(obj.Blinks)
                scatter3(ax, obj.Blinks(i).x1, -obj.Blinks(i).ts, obj.Blinks(i).y1, 'red', 'diamond', 'filled')
                hold on
                scatter3(ax, obj.Blinks(i).x2, -obj.Blinks(i).ts, obj.Blinks(i).y2, 'green', 'diamond', 'filled')
            end
            set(gca, 'xtick', 0:obj.TileSizes(1):obj.Dimensions(1))
            set(gca, 'ztick', 0:obj.TileSizes(2):obj.Dimensions(2))
            zlim([0 obj.Dimensions(2)])
            xlim([0 obj.Dimensions(1)])
            ylabel('time [s]')
            xlabel('input frame x direction')
            zlabel('input frame y direction')
            yt=arrayfun(@num2str,get(gca,'ytick')/-1000000, 'UniformOutput', false);
            set(gca, 'yticklabel', yt);
            set(gca, 'ytick', -round(obj.EventstreamGrid1.ts(end)/100000000, 1)*100000000:10000000:0)
            title([obj.Parent.Name, ' rec No. ', int2str(obj.Number), ', corr threshold: 0.', int2str(obj.Parent.CorrelationThreshold*100), ', model temporal resolution: ', int2str(obj.Parent.ModelSubsamplingRate), 'us'])
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
            set(gca, 'xticklabel', xt)
            set(gca, 'zticklabel', zt)
            zlim([0 obj.Dimensions(2)])
            xlim([0 obj.Dimensions(1)])
            ylabel('time [s]')
            xlabel('input frame x direction')
            zlabel('input frame y direction')
            yt=arrayfun(@num2str,get(gca,'ytick')/-1000000, 'UniformOutput', false);
            set(gca, 'yticklabel', yt);
            set(gca, 'ytick', -round(obj.EventstreamGrid1.ts(end)/100000000, 1)*100000000:10000000:0)

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