classdef Recording < handle
    properties
        Number
        Eventstream
        Faces = Face.empty
        EventstreamGrid1
        EventstreamGrid2
        Grids = cell(1,2)
        IsTrainingRecording
        Center
        Left
        Right
        Dimensions = [304, 240]
        GridSizes = [16, 16]
        GT = []
        AverageTrackingError = 0
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
            if amplitudescale ~= 1 && amplitudescale ~= obj.Parent.AmplitudeScale
                obj.Parent.AmplitudeScale = amplitudescale;
                disp(['Amplitude scale: ', int2str(amplitudescale)])
            end
            modelblink.AverageOn = filter(movingAverageWindow/amplitudescale, 1, modelOn);
            modelblink.VarianceOn = filter(movingAverageWindow/amplitudescale, 1, sqrt(varianceOn));
            modelblink.AverageOff = filter(movingAverageWindow/amplitudescale, 1, modelOff);
            modelblink.VarianceOff = filter(movingAverageWindow/amplitudescale, 1, sqrt(varianceOff));
        end
        
        function calculatecorrelation(obj, varargin)
            disp(['calculating correlation for subject ', obj.Parent.Name, ', rec no ', num2str(obj.Number)])
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
        
        function calculatescalecorrelation(obj, varargin)
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
                    if (i-1) * tile_width <= 87
                        addconst = obj.Left.AmplitudeScaleScale;
                    elseif (i-1) * tile_width >= 200
                        addconst = obj.Right.AmplitudeScaleScale;
                    else
                        addconst = obj.Center.AmplitudeScaleScale;
                    end
                    tile = activity(tile, obj.Parent.ActivityDecayConstant, (1 / obj.Parent.AmplitudeScale) * addconst, true);
                    tile = quick_correlation(tile, modelblink.AverageOn, modelblink.AverageOff, obj.Parent.AmplitudeScale / addconst, obj.Parent.BlinkLength, obj.Parent.ModelSubsamplingRate);
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
                    if (i-1) * tile_width + floor(tile_width/2) <= 87
                        addconst = obj.Left.AmplitudeScaleScale;
                    elseif (i-1) * tile_width + floor(tile_width/2) >= 200
                        addconst = obj.Right.AmplitudeScaleScale;
                    else
                        addconst = obj.Center.AmplitudeScaleScale;
                    end
                    tile = activity(tile, obj.Parent.ActivityDecayConstant, (1 / obj.Parent.AmplitudeScale) * addconst, true);
                    tile = quick_correlation(tile, modelblink.AverageOn, modelblink.AverageOff, obj.Parent.AmplitudeScale / addconst, obj.Parent.BlinkLength, obj.Parent.ModelSubsamplingRate);
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
      
        function detectblinks(obj)
            if isempty(obj.EventstreamGrid1)
                disp(['no correlation data present for rec no ', num2str(obj.Number), ', starting computation...'])
                obj.calculatecorrelation;
            end
            disp(['detecting blink for subject ', obj.Parent.Name, ', rec no ', num2str(obj.Number)])
            for f = 1:3
                obj.Faces(f) = Face;
            end
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
                if combinedGrid.y(indices(i)) > 120 && combinedGrid.ts(indices(i)) - combinedGrid.ts(indices(i-2)) < maximumDifference && ~isequal(combinedGrid.x(indices(i)), combinedGrid.x(indices(i-1))) && ~isequal(combinedGrid.x(indices(i)), combinedGrid.x(indices(i-2))) && ~isequal(combinedGrid.x(indices(i-1)), combinedGrid.x(indices(i-2)))%check temporal coherence
                    %last 3 events and next one are close enough in time and have the
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
                        diff = abs(rightMean - leftMean);
                        if leftDelta(1) < tileWidth && leftDelta(2) < tileHeight && right(1) < tileWidth && right(2) < tileHeight && diff(1) > tileWidth && diff(1) < 50 && diff(2) < tileHeight
                            if rightMean(1) < 87
                                obj.Faces(1).addblink(Blink(leftMean(1), leftMean(2), rightMean(1), rightMean(2), combinedGrid.ts(indices(i))));
                            elseif leftMean(1) > 200
                                obj.Faces(3).addblink(Blink(leftMean(1), leftMean(2), rightMean(1), rightMean(2), combinedGrid.ts(indices(i))));
                            else
                                obj.Faces(2).addblink(Blink(leftMean(1), leftMean(2), rightMean(1), rightMean(2), combinedGrid.ts(indices(i))));
                            end
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
                    if  leftDiff(1) < tileWidth && leftDiff(2) < tileHeight && triplet(3,1) - leftMean(1) > tileWidth && triplet(3,1) - leftMean(1) < 50 && abs(triplet(3,2) - leftMean(2)) < tileHeight
                        if triplet(3,1) < 87
                            obj.Faces(1).addblink(Blink(leftMean(1), leftMean(2), triplet(3,1), leftMean(2), combinedGrid.ts(indices(i))));
                        elseif leftMean(1) > 200
                            obj.Faces(3).addblink(Blink(leftMean(1), leftMean(2), triplet(3,1), leftMean(2), combinedGrid.ts(indices(i))));
                        else
                            obj.Faces(2).addblink(Blink(leftMean(1), leftMean(2), triplet(3,1), leftMean(2), combinedGrid.ts(indices(i))));
                        end
                    end
                    %two on the right
                    rightDiff = abs(triplet(3,:) - triplet(2,:));
                    rightMean = ((triplet(3,:) + triplet(2,:))/2);
                    if  rightDiff(1) < tileWidth && rightDiff(2) < tileHeight && rightMean(1) - triplet(1,1) > tileWidth && rightMean(1) - triplet(1,1) < 50 && abs(triplet(1,2) - rightMean(2)) < tileHeight
                        if triplet(3,1) < 87
                            obj.Faces(1).addblink(Blink(triplet(1,1), rightMean(2), rightMean(1), rightMean(2), combinedGrid.ts(indices(i))));
                        elseif triplet(1,1) > 200
                            obj.Faces(3).addblink(Blink(triplet(1,1), rightMean(2), rightMean(1), rightMean(2), combinedGrid.ts(indices(i))));
                        else
                            obj.Faces(2).addblink(Blink(triplet(1,1), rightMean(2), rightMean(1), rightMean(2), combinedGrid.ts(indices(i))));
                        end
                    end
                end
            end
        end
                
        function calculatetracking(obj)
            if isempty(obj.Faces)
               disp(['no blinks detected yet for rec no ', num2str(obj.Number), ', triggering detection...'])
               obj.detectblinks
            end
            disp(['calculating tracking for subject ', obj.Parent.Name, ', rec no ', num2str(obj.Number)])
            rec = obj.Eventstream;
            blinkTimes = cell(1, length(obj.Faces));
            blinkCount = zeros(1, length(obj.Faces));
            blinkIndex = ones(1, length(obj.Faces));
            blobNumbers = zeros(1, length(obj.Faces));
            first = rec.ts(end);
            for f = 1:length(obj.Faces)
                rec.faces(f).leftTracker.x = nan(1,length(rec.ts));
                rec.faces(f).leftTracker.y = nan(1,length(rec.ts));
                rec.faces(f).rightTracker.x = nan(1,length(rec.ts));
                rec.faces(f).rightTracker.y = nan(1,length(rec.ts));
                if obj.Faces(f).Blinks(1).ts < first
                    first = obj.Faces(f).Blinks(1).ts;
                end
                blinkTimes{f} = obj.Faces(f).getblinktimes;
                blinkCount(f) = length(obj.Faces(f).Blinks);
            end
            start = find(first);
            stop = length(rec.ts);
            for i = start:stop
                probability = 0;
                win = 0;
                for f = 1:length(obj.Faces)
                    if blinkIndex(f) <= blinkCount(f) && blinkTimes{f}(blinkIndex(f)) < rec.ts(i)
                        %for l = 1:length(obj.Faces.Blinks)
                        %    if blinkTimes{f} == obj.Faces(f).Blinks(l).ts
                        obj.Faces(f).resettracker(obj.Faces(f).Blinks(blinkIndex(f)));
                        blinkIndex(f) = blinkIndex(f) + 1;
                        blobNumbers(f) = 2;
                        %blinkTimes{f}(1) = [];
                        break;
                    else
                        for b = 1:blobNumbers(f)
                            prob = obj.Faces(f).Blobs(b).getblobprobability(rec.x(i), rec.y(i));
                            if prob > probability && prob > 0.003
                                probability = prob;
                                win = [f, b];
                            end
                        end
                    end
                end
                if win(1) ~= 0
                    obj.Faces(win(1)).Blobs(win(2)).updatebyevent(rec.x(i), rec.y(i));
                    pos = obj.Faces(win(1)).gettrackerpositions;
                    rec.faces(win(1)).leftTracker.x(i) = pos(1,1);
                    rec.faces(win(1)).leftTracker.y(i) = pos(1,2);
                    rec.faces(win(1)).rightTracker.x(i) = pos(2,1);
                    rec.faces(win(1)).rightTracker.y(i) = pos(2,2);
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
        
        function plotblinks(obj, varargin)
            if isempty(obj.Faces)
                disp('Cannot plot blinks because none have been detected yet, starting detectblinks...')
                obj.detectblinks;
            end
            if nargin > 1
                ax = varargin{1};
            else
                figure;
                ax = gca;
            end
            colors = {'blue', 'black', 'magenta'};
            for f = 1:length(obj.Faces)
                for i = 1:length(obj.Faces(f).Blinks)
                    scatter3(ax, obj.Faces(f).Blinks(i).x1, -obj.Faces(f).Blinks(i).ts, obj.Faces(f).Blinks(i).y1, 200, colors{f}, 'diamond', 'Displayname', 'left blink detected');
                    hold on
                    scatter3(ax, obj.Faces(f).Blinks(i).x2, -obj.Faces(f).Blinks(i).ts, obj.Faces(f).Blinks(i).y2, 200, colors{f}, 'diamond', 'Displayname', 'right blink detected');
                end
            end
            title(sprintf([obj.Parent.Name, ' rec No. ', int2str(obj.Number), ', corr threshold: ', num2str(obj.Parent.CorrelationThreshold), ', \nmodel temporal resolution: ', int2str(obj.Parent.ModelSubsamplingRate), 'us, \nfirst blink in the middle detected at ', num2str(round(obj.Faces(2).Blinks(1).ts/1000000,3)), 's']))
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
            set(gca, 'ytick', -round(obj.EventstreamGrid1.ts(end)/100000000, 1)*100000000:10000000:0)
            yt=arrayfun(@num2str,get(gca,'ytick')/-1000000, 'UniformOutput', false);
            set(gca, 'yticklabel', yt);
            legend(ax, 'left eye detected', 'right eye detected', 'Location', 'best')
        end

        function result = readGT(obj)
            path = ['/home/gregorlenz/Recordings/face-detection/', obj.Parent.Parent.DatasetType, '/', obj.Parent.Name, '/', num2str(obj.Number), '/run', num2str(obj.Number), '-frames.csv'];
            result = false;
            if exist(path, 'file') == 2
                csv = csvread(path);
                obj.GT.ts = csv(:,1)';
                obj.GT.x = (csv(:,2)+csv(:,4)/2)';
                obj.GT.y = obj.Dimensions(2) - (csv(:,3)' + 0.40 * csv(:,4)');
                %obj.GT.width = csv(:,4)';
                result = true;
            end
        end
        
        function res = calculatetrackingerror(obj)
            if obj.readGT
                if ~isfield(obj.Eventstream, 'leftTracker')
                    disp(['no tracking data present for rec no ', num2str(obj.Number), ', starting computation...'])
                    obj.calculatetracking
                end
                %figure
                tracker = (obj.Eventstream.leftTracker + obj.Eventstream.rightTracker) / 2;
                trackerX = tracker(:,1)';
                trackerY = tracker(:,2)';
                [~, ia, ~] = unique(obj.Eventstream.ts);
                interpolatedX = interp1(obj.Eventstream.ts(ia), trackerX(ia), obj.GT.ts);
                interpolatedY = interp1(obj.Eventstream.ts(ia), trackerY(ia), obj.GT.ts);
                %scatter3(obj.GT.ts, obj.GT.x, obj.GT.y)
                %hold on
                %scatter3(obj.GT.ts, interpolatedX, interpolatedY);
                deviation = sqrt((obj.GT.x - interpolatedX).^2 + (obj.GT.y - interpolatedY).^2);
                obj.AverageTrackingError = mean(deviation(~isnan(deviation)));
                disp(['tracking error for rec no ', num2str(obj.Number), ': ', num2str(obj.AverageTrackingError)])
                %rel = sum(deviation(~isnan(deviation)))/obj.GT.ts(end)
                res = true;
            else
                disp(['could not read GT for rec no ', num2str(obj.Number)])
                res = false;
            end
        end
        
        function plottracking(obj, varargin)
            if ~isfield(obj.Eventstream, 'leftTracker')
               disp(['no tracking data present for rec no ', num2str(obj.Number), ', starting computation...'])
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
            
            %print screenshots
            blinkstoprint = [1 1 length(obj.Blinks)];
            for index = 2:length(obj.Blinks)
                if obj.Blinks(index).ts > 11000000
                    blinkstoprint(2) = index;
                    break;
                end
            end
            for i = 1:length(blinkstoprint)
                closestScreenshot = round(obj.Blinks(blinkstoprint(i)).ts / 1000000);
                framepath = (['/home/gregorlenz/Recordings/face-detection/', obj.Parent.Parent.DatasetType, '/', lower(obj.Parent.Name), '/', num2str(obj.Number), '/frames/', num2str(closestScreenshot), '.png']);
                if exist(framepath, 'file') == 2
                    img = imread(framepath);
                    %img = double(img)/255;
                    %index1 = img(:,:,1) == 1;
                    %index2 = img(:,:,2) == 1;
                    %index3 = img(:,:,3) == 1;
                    %indexWhite = index1+index2+index3==3;
                    %for idx = 1 : 3
                    %   rgb = img(:,:,idx);     % extract part of the image
                    %   rgb(indexWhite) = NaN;  % set the white portion of the image to NaN
                    %   img(:,:,idx) = rgb;     % substitute the update values
                    %end
                    X = [0 obj.Dimensions(1); 0 obj.Dimensions(1)];
                    Y = -[obj.Blinks(blinkstoprint(i)).ts obj.Blinks(blinkstoprint(i)).ts; obj.Blinks(blinkstoprint(i)).ts obj.Blinks(blinkstoprint(i)).ts];
                    Z = [obj.Dimensions(2) obj.Dimensions(2); 0 0];
                    surface(X, Y, Z, img,'FaceColor','texturemap')%,'FaceAlpha', 0.7);
                end
            end
            %format axes
            title(sprintf([obj.Parent.Name, ' rec No. ', int2str(obj.Number), ', corr threshold: ', num2str(obj.Parent.CorrelationThreshold), ', \nmodel temporal resolution: ', int2str(obj.Parent.ModelSubsamplingRate), 'us, \nfirst blink detected at ', num2str(round(obj.Blinks(1).ts/1000000,3)), 's']))
            xlim([0 obj.Dimensions(1)])
            zlim([0 obj.Dimensions(2)])
            ylim([-round(obj.EventstreamGrid1.ts(end)/100000000, 1)*100000000 0]);
            a = legend('show');
            a.String(end-length(blinkstoprint)+1:end) = '';
            
            %print GT
            if obj.readGT
                scatter3(ax, obj.GT.x, -obj.GT.ts, obj.GT.y, '.', 'blue')
            end
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
            opts1={'FaceAlpha', 0.7, 'FaceColor', obj.Parent.Parent.OnColour};%rot
            opts2={'FaceAlpha', 0.7, 'FaceColor', obj.Parent.Parent.OffColour};%blau

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
            fill_between(x, y1, y2, y1 < y2, opts1{:});
            fill_between(x, z, y1, y1 > z, opts2{:});
            %sometimes it is desired to rather show the events 
            %stem(eye.ts, eye.activityOn/subjects.(names{s}).AmplitudeScale);
            %stem(eye.ts, -eye.activityOff/subjects.(names{s}).AmplitudeScale);
        end

    end

end