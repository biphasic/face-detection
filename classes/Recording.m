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
            obj.Center = Blinklocation(obj);
            obj.Left = Blinklocation(obj);
            obj.Right = Blinklocation(obj);
            obj.Parent = parent;
        end
        
        function tilesizes = get.TileSizes(obj)
            tilesizes = obj.Dimensions ./ obj.GridSizes;
        end
        function set.GridSizes(obj, sizes)
            if mod([304, 240], sizes) ~= 0
                error('grid size does not align well with dimensions of an ATIS recording')
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
        
        function calculatecorrelation(obj, varargin)
            if nargin > 1 && isa(varargin{1}, 'Modelblink')
                disp('inserted new Modelblink for correlation')
                modelblink = varargin{1};
            else
                disp('Using subject-specific Modelblink')
                modelblink = obj.Parent.Modelblink;
            end
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
                    tile = activity(tile, obj.Parent.ActivityDecayConstant, 1 / obj.Parent.AmplitudeScale, true);
                    tile = quick_correlation(tile, modelblink.AverageOn, modelblink.AverageOff, obj.Parent.AmplitudeScale, obj.Parent.BlinkLength, obj.Parent.ModelSubsamplingRate);
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
                    tile = activity(tile, obj.Parent.ActivityDecayConstant, 1 / obj.Parent.AmplitudeScale, true);
                    tile = quick_correlation(tile, modelblink.AverageOn, modelblink.AverageOff, obj.Parent.AmplitudeScale, obj.Parent.BlinkLength, obj.Parent.ModelSubsamplingRate);
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
        
        function calculatecorrelationwithsuperblink(obj)
            obj.calculatecorrelation(obj.Parent.Parent.Supermodel)
        end
      
        function detectblinks(obj)
            if isempty(obj.EventstreamGrid1)
                disp('No correlation data present, starting computation...')
                obj.calculatecorrelation;
            end
            obj.Blinks = Blink(1,1,1,1,1);
            blinkIndex = 1;
            combinedGrid = merge_streams(obj.EventstreamGrid1, obj.EventstreamGrid2);
            mask = combinedGrid.patternCorrelation>obj.Parent.CorrelationThreshold;
            
            maximumDifference = 50000;
            tileWidth = obj.TileSizes(1);
            tileHeight = obj.TileSizes(2);
            indices = find(mask);
            skip = 0;
            for i = 3:length(indices)
                if skip > 0
                    skip = skip - 1;
                    continue
                end
                %last three events are close enough in time and do not have
                %the same x value
                if combinedGrid.ts(indices(i)) - combinedGrid.ts(indices(i-2)) < maximumDifference && ~isequal(combinedGrid.x(indices(i)), combinedGrid.x(indices(i-1))) && ~isequal(combinedGrid.x(indices(i)), combinedGrid.x(indices(i-2))) && ~isequal(combinedGrid.x(indices(i-1)), combinedGrid.x(indices(i-2)))%check temporal coherence
                    %last 4 events are close enough in time and have the
                    %same x value
                    if i ~= length(indices) && combinedGrid.ts(indices(i)) - combinedGrid.ts(indices(i+1)) < maximumDifference && ~isequal(combinedGrid.x(indices(i)), combinedGrid.x(indices(i+1))) && ~isequal(combinedGrid.x(indices(i-1)), combinedGrid.x(indices(i+1))) && ~isequal(combinedGrid.x(indices(i-2)), combinedGrid.x(indices(i+1)) )
                        quadruplet = zeros(4, 2);
                        for row = 1:4
                            quadruplet(row,:) = [combinedGrid.x(indices(i+2-row)), combinedGrid.y(indices(i+2-row))];
                        end
                        quadruplet = sortrows(quadruplet);
                        leftDelta = abs(quadruplet(2,:) - quadruplet(1,:));
                        leftMean = (quadruplet(2,:) + quadruplet(1,:))/2;
                        right = abs(quadruplet(4,:) - quadruplet(3,:));
                        rightMean = (quadruplet(4,:) + quadruplet(3,:))/2;
                        diff = (rightMean - leftMean);
                        if leftDelta(1) < tileWidth && leftDelta(2) < tileHeight && right(1) < tileWidth && right(2) < tileHeight && diff(1) >= tileWidth && diff(1) < 80 && diff(2) < tileHeight
                            obj.Blinks(blinkIndex) = Blink(leftMean(1), leftMean(2), rightMean(1), rightMean(2), combinedGrid.ts(indices(i)));
                            blinkIndex = blinkIndex + 1;
                            skip = 2;
                            continue;
                        end
                    end
                    %last three events, either two on the left or two on
                    %the right
                    triplet = zeros(3, 2);
                    for row = 1:3
                        triplet(row,:) = [combinedGrid.x(indices(i-(row-1))), combinedGrid.y(indices(i-(row-1)))];
                    end
                    triplet = sortrows(triplet);
                    %two on the left
                    leftDiff = abs(triplet(2,:) - triplet(1,:));
                    leftMean = ((triplet(2,:) + triplet(1,:))/2);
                    if  leftDiff(1) < tileWidth && leftDiff(2) < tileHeight && triplet(3,1) - leftMean(1) > tileWidth/2 && triplet(3,1) - leftMean(1) < 80 && abs(triplet(3,2) - leftMean(2)) < tileHeight
                        obj.Blinks(blinkIndex) = Blink(leftMean(1), leftMean(2), triplet(3,1), leftMean(2), combinedGrid.ts(indices(i)));
                        blinkIndex = blinkIndex + 1;
                    end
                    %two on the right
                    rightDiff = abs(triplet(3,:) - triplet(2,:));
                    rightMean = ((triplet(3,:) + triplet(2,:))/2);
                    if  rightDiff(1) < tileWidth && rightDiff(2) < tileHeight && rightMean(1) - triplet(1,1) > tileWidth && rightMean(1) - triplet(1,1) < 80 && abs(triplet(1,2) - rightMean(2)) < tileHeight
                        obj.Blinks(blinkIndex) = Blink(triplet(1,1), rightMean(2), rightMean(1), rightMean(2), combinedGrid.ts(indices(i)));
                        blinkIndex = blinkIndex + 1;
                    end
                end
            end
        end
                
        function calculatetracking(obj)
            if isempty(obj.Blinks)
               disp('No blinks detected yet which are necessary to calcute tracking')
               obj.detectblinks
            end
            rec = obj.Eventstream;
            rec.leftTracker = nan(length(rec.ts), 2);
            rec.rightTracker = nan(length(rec.ts), 2);
            blobs = Blob(1,1,1,1,1);
            blinkIndex = 1;
            blinkCount = length(obj.Blinks);
            start = find(rec.ts == obj.Blinks(1).ts);
            stop = length(rec.ts);
            for i = start:stop
                if blinkIndex <= blinkCount && rec.ts(i) >= obj.Blinks(blinkIndex).ts
                    blobs = Blob(obj.Blinks(blinkIndex).x1, obj.Blinks(blinkIndex).y1, 5, 0, 3);
                    blobs(2) = Blob(obj.Blinks(blinkIndex).x2, obj.Blinks(blinkIndex).y2, 5, 0, 3);
                    blinkIndex = blinkIndex + 1;
                else
                    for b = 1:length(blobs)
                        blobs(b).updatebyevent(rec.x(i), rec.y(i));
                    end
                    rec.leftTracker(i,1) = blobs(1).x;
                    rec.leftTracker(i,2) = blobs(1).y;
                    rec.rightTracker(i,1) = blobs(2).x;
                    rec.rightTracker(i,2) = blobs(2).y;    
                end
            end
            obj.Eventstream = rec;
        end
        
        function plotcorrelation(obj, varargin)
            if isempty(obj.EventstreamGrid1)
                disp("You haven't run the correlation yet, computing now...")
                obj.calculatecorrelation
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
            title(sprintf([obj.Parent.Name, ' rec No. ', int2str(obj.Number), ', corr threshold: 0.', int2str(obj.Parent.CorrelationThreshold*100), ', \nmodel temporal resolution: ', int2str(obj.Parent.ModelSubsamplingRate), 'us']))
            %x/z
            xlabel('tile number x direction')
            xlim([0 obj.Dimensions(1)])
            set(gca, 'xtick', 0:obj.TileSizes(1):obj.Dimensions(1))
            xt=arrayfun(@num2str,get(gca,'xtick')/obj.TileSizes(1), 'UniformOutput', false);
            set(gca, 'xticklabel', xt)
            zlabel('tile number y direction')
            zlim([0 obj.Dimensions(2)])
            set(gca, 'ztick', 0:obj.TileSizes(2):obj.Dimensions(2))
            zt=arrayfun(@num2str,get(gca,'ztick')/obj.TileSizes(2), 'UniformOutput', false);
            set(gca, 'zticklabel', zt)
            %y
            ylabel('time [s]')
            ylim([-round(obj.EventstreamGrid1.ts(end)/100000000, 1)*100000000 0]);
            set(gca, 'ytick', -round(obj.EventstreamGrid1.ts(end)/100000000, 1)*100000000:10000000:0)
            yt=arrayfun(@num2str,get(gca,'ytick')/-1000000, 'UniformOutput', false);
            set(gca, 'yticklabel', yt);
        end
        
        function continuousdetection(obj)
        % continuous detection and scaling according to distance between trackers
        tic
            counter = 0;
            rec = obj.Eventstream;
            modelblink = obj.Parent.Modelblink;
            growConstant = obj.Parent.AmplitudeScale;
            allTimestamps = rec.ts;
            grid(obj.GridSizes(1), obj.GridSizes(2)) = Tile();
            for i = 1:obj.GridSizes(1)
                for j = 1:obj.GridSizes(2)
                    grid(i, j).initialise(obj.Parent.ActivityDecayConstant, growConstant, allTimestamps, obj.Parent.BlinkLength);
                end
            end
            tileSizes = obj.TileSizes;

            for i = 1:length(rec.ts)/8
                row = ceil(rec.y(i) / tileSizes(2));
                col = ceil(rec.x(i) / tileSizes(1));
                currentts = allTimestamps(i);
                pol = rec.p(i);
                if row == 0
                    row = 1;
                end
                if col == 0
                    col = 1;
                end
                
                % update activity
                grid(row, col).updateactivity(currentts, pol, growConstant);

                % update buffers
                numOff = grid(row, col).updatebuffer(i, currentts, pol, growConstant);
                
                % correlate buffer if high enough
                if numOff > growConstant/3 && numOff < 5*growConstant
                    counter = counter + 1;
                    %grid(row.col).correlation(modelblink, obj.Parent.ModelSubsamplingRate)
                end
            end
            disp(counter)
            delete(grid)
        toc
        end

        function plotblinks(obj, varargin)
            if isempty(obj.Blinks)
                disp('Cannot plot blinks because none have been detected yet, starting detectblinks...')
                obj.detectblinks;
            end
            if nargin > 1
                ax = varargin{1};
            else
                figure;
                ax = gca;
            end
            for i = 1:length(obj.Blinks)
                scatter3(ax, obj.Blinks(i).x1, -obj.Blinks(i).ts, obj.Blinks(i).y1, 200, 'black', 'diamond', 'Displayname', 'left blink detected');
                hold on
                scatter3(ax, obj.Blinks(i).x2, -obj.Blinks(i).ts, obj.Blinks(i).y2, 200, 'black', 'diamond', 'Displayname', 'right blink detected');
            end
            title(sprintf([obj.Parent.Name, ' rec No. ', int2str(obj.Number), ', corr threshold: ', num2str(obj.Parent.CorrelationThreshold), ', \nmodel temporal resolution: ', int2str(obj.Parent.ModelSubsamplingRate), 'us, \nfirst blink detected at ', num2str(round(obj.Blinks(1).ts/1000000,3)), 's']))
            % x/z
            xlabel('input frame x direction');
            xlim([0 obj.Dimensions(1)])
            set(gca, 'xtick', 0:obj.TileSizes(1)*2:obj.Dimensions(1))
            set(gca, 'xticklabels', 0:obj.TileSizes(1)*2:obj.Dimensions(1))
            zlabel('input frame y direction')
            zlim([0 obj.Dimensions(2)])
            set(gca, 'ztick', 0:obj.TileSizes(2)*2:obj.Dimensions(2))
            set(gca, 'zticklabels', 0:obj.TileSizes(2)*2:obj.Dimensions(2))
            % y
            ylabel('time [s]')
            ylim([-round(obj.EventstreamGrid1.ts(end)/100000000, 1)*100000000 0]);
            yt=arrayfun(@num2str,get(gca,'ytick')/-1000000, 'UniformOutput', false);
            set(gca, 'yticklabel', yt);
            set(gca, 'ytick', -round(obj.EventstreamGrid1.ts(end)/100000000, 1)*100000000:10000000:0)
            legend(ax, 'left eye detected', 'right eye detected', 'Location', 'best')
        end

        function plottracking(obj, varargin)
            if ~isfield(obj.Eventstream, 'leftTracker')
               disp('No tracking data present, starting computation...')
               obj.calculatetracking
            end
            if nargin > 1
                ax = varargin{1};
            else
                figure;
                ax = gca;
            end
            obj.plotblinks(ax)
            scatter3(ax, obj.Eventstream.leftTracker(:,1), -obj.Eventstream.ts, obj.Eventstream.leftTracker(:,2), '.', 'red',  'Displayname', 'left eye tracker');
            hold on 
            scatter3(ax, obj.Eventstream.rightTracker(:,1), -obj.Eventstream.ts, obj.Eventstream.rightTracker(:,2), '.', 'green', 'Displayname', 'right eye tracker');
            X = [0 obj.Dimensions(1); 0 obj.Dimensions(1)];
            Y = -[obj.Blinks(1).ts obj.Blinks(1).ts; obj.Blinks(1).ts obj.Blinks(1).ts];
            Z = [obj.Dimensions(2) obj.Dimensions(2); 0 0];
            im = imread('/home/gregorlenz/Téléchargements/frames/1.png');
            surface(X, Y, Z, im, 'facecolor', 'texturemap', 'edgecolor', 'none');
            title(sprintf([obj.Parent.Name, ' rec No. ', int2str(obj.Number), ', corr threshold: ', num2str(obj.Parent.CorrelationThreshold), ', \nmodel temporal resolution: ', int2str(obj.Parent.ModelSubsamplingRate), 'us, \nfirst blink detected at ', num2str(round(obj.Blinks(1).ts/1000000,3)), 's']))
            xlim([0 obj.Dimensions(1)])
            zlim([0 obj.Dimensions(2)])
            ylim([-round(obj.EventstreamGrid1.ts(end)/100000000, 1)*100000000 0]);
            a = legend('show');
            a.String(end) = '';
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
            y1 = continuum.activityOff;
            y2 = continuum.activityOn;
            fill_between(x, y1, y2, y1 < y2, opts2{:});
            fill_between(x, z, y1, y1 > z, opts1{:});
            %sometimes it is desired to rather show the events 
            %stem(eye.ts, eye.activityOn/subjects.(names{s}).AmplitudeScale);
            %stem(eye.ts, -eye.activityOff/subjects.(names{s}).AmplitudeScale);
        end

    end

end