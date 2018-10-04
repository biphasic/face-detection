classdef Recording < handle
    %RECORDING Summary of this class goes here
    %   Detailed explanation goes here
    
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
            %RECORDING Construct all the objects
            obj.Eventstream = eventStream;
            obj.IsTrainingRecording = isTrainingRecording;
            obj.Center = Blinks;
            obj.Left = Blinks;
            obj.Right = Blinks;
            obj.Grids = cell(1,2);
            obj.Parent = parent;
        end
        
        function [centerAverageOn, centerAverageOff] = getcenteraverages(obj)
            [centerAverageOn, centerAverageOff] = obj.Center.getaverages(obj.Parent.AmplitudeScale, obj.Eventstream, obj.Parent.BlinkLength);
        end
        
        function [blinksOn, blinksOff] = getcenterblinks(obj)
            [blinksOn, blinksOff] = obj.Center.getblinks(obj.Parent.AmplitudeScale, obj.Eventstream, obj.Parent.BlinkLength);
        end
        
        function [leftAverageOn, leftAverageOff] = getleftaverages(obj)
            [leftAverageOn, leftAverageOff] = obj.Left.getaverages(obj.Parent.AmplitudeScale, obj.Eventstream, obj.Parent.BlinkLength);
        end
        
        function [blinksOn, blinksOff] = getleftblinks(obj)
            [blinksOn, blinksOff] = obj.Left.getblinks(obj.Parent.AmplitudeScale, obj.Eventstream, obj.Parent.BlinkLength);
        end
        
        function [rightAverageOn, rightAverageOff] = getrightaverages(obj)
            [rightAverageOn, rightAverageOff] = obj.Right.getaverages(obj.Parent.AmplitudeScale, obj.Eventstream, obj.Parent.BlinkLength);
        end
        
        function [blinksOn, blinksOff] = getrightblinks(obj)
            [blinksOn, blinksOff] = obj.Right.getblinks(obj.Parent.AmplitudeScale, obj.Eventstream, obj.Parent.BlinkLength);
        end
        
        function [blinksOn, blinksOff] = getblinks(obj)
            if ~isempty(obj.Center.Location) && ~isempty(obj.Center.Times)
                [blinksOn.Center, blinksOff.Center] = obj.getcenterblinks();
            end
            if ~isempty(obj.Left.Location) && ~isempty(obj.Left.Times)
                [blinksOn.Left, blinksOff.Left] = obj.getleftblinks();
            end
            if ~isempty(obj.Right.Location) && ~isempty(obj.Right.Times)
                [blinksOn.Right, blinksOff.Right] = obj.getrightblinks();
            end
            if isempty(blinksOn)
                error('got no blinks')
            end
        end
        
        function [filteredAverageOn, filteredAverageOff, filteredSigmaOn, filteredSigmaOff] = getmodelblink(obj, smoothingFactor)
            modelOn = zeros(1,3000);
            modelOff = zeros(1,3000);
            varianceOn = zeros(1,3000);
            varianceOff = zeros(1,3000);
            count = 0;
            if ~isempty(obj.Center.Location) && ~isempty(obj.Center.Times)
                [centerOn, centerOff] = obj.getcenteraverages();
                modelOn = modelOn + centerOn;
                modelOff = modelOff + centerOff;
                count = count + 1;
            end
            if ~isempty(obj.Left.Location) && ~isempty(obj.Left.Times)
                [leftOn, leftOff] = obj.getleftaverages();
                modelOn = modelOn + leftOn;
                modelOff = modelOff + leftOff;
                count = count + 1;
            end
            if ~isempty(obj.Right.Location) && ~isempty(obj.Right.Times)
                [rightOn, rightOff] = obj.getrightaverages();
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
            filteredAverageOn = filter(movingAverageWindow, 1, modelOn);
            filteredSigmaOn = filter(movingAverageWindow, 1, sqrt(varianceOn));
            filteredAverageOff = filter(movingAverageWindow, 1, modelOff);
            filteredSigmaOff = filter(movingAverageWindow, 1, sqrt(varianceOff));
        end
        
        function [] = calculatecorrelation(obj)
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
         end

    end

end