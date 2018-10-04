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
            
    end
end

