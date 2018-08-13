classdef Blinks
    %BLINKS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Location
        Times
    end
    
    properties (Dependent)
        Average
    end
    
    methods
        function obj = Blinks()
            %BLINKS Construct an instance of this class
            %   Detailed explanation goes here
            %obj.Property1 = inputArg1 + inputArg2;
        end
        
        function blinks = getblinkarray(blinkLength)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            blinks = blinkLength;
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

