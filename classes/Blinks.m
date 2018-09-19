classdef Blinks
    %BLINKS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Location
        Times
    end
    
    methods
        function obj = Blinks()
            %BLINKS Construct an instance of this class
            %   Detailed explanation goes here
            %obj.Property1 = inputArg1 + inputArg2;
        end
        
        function [blinksOn, blinksOff] = getblinks(obj, amplitudeScale, rec, blinkLength)
            if ~isempty(obj.Location) && ~isempty(obj.Times)
                eye = crop_spatial(rec, obj.Location(1), obj.Location(2), 19, 15);
                eye = activity(eye, 50000, true);
                scaleFactor = 10;
                eye = shannonise(eye, scaleFactor);
                blinkRow = obj.Times / scaleFactor;
                blinklength = blinkLength / scaleFactor;
                blinksOn = zeros(nnz(obj.Times), blinklength/ scaleFactor);
                blinksOff = blinksOn;
                
                for i = 1:nnz(blinkRow)
                    indexes = eye.ts >= blinkRow(i) & eye.ts < (blinkRow(i)+blinklength);
                    % normalise over number of blinkRow and a normalising
                    % factor that is specific for each subject
                    blinksOn(i,:) = eye.activityOn(indexes) / amplitudeScale;
                    blinksOff(i,:) = eye.activityOff(indexes) / amplitudeScale;
                end
            else
                error('no blinks saved for this location');
            end
        end
                
        function [averageOn, averageOff] = getaverages(obj, amplitudeScale, rec, blinkLength)
            if ~isempty(obj.Location) && ~isempty(obj.Times)
                eye = crop_spatial(rec, obj.Location(1), obj.Location(2), 19, 15);
                eye = activity(eye, 50000, true);
                scaleFactor = 10;
                eye = shannonise(eye, scaleFactor);
                blinkRow = obj.Times / scaleFactor;
                blinklength = blinkLength / scaleFactor;
                masterOn = zeros(1, blinklength/ scaleFactor);
                masterOff = masterOn;
                
                for i = 1:nnz(blinkRow)
                    indexes = eye.ts >= blinkRow(i) & eye.ts < (blinkRow(i)+blinklength);
                    % normalise over number of blinkRow and a normalising factor that is specific to each recording
                    scaledAverageOn = eye.activityOn(indexes) / amplitudeScale;
                    masterOn = masterOn + scaledAverageOn / nnz(blinkRow);
                    scaledAverageOff = eye.activityOff(indexes) / amplitudeScale;
                    masterOff = masterOff + scaledAverageOff / nnz(blinkRow);
                end
                averageOn = masterOn;
                averageOff = masterOff;
                
            else
                error('no blinks saved for this location');
            end
        end
            
    end
end

