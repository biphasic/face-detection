classdef Recording < handle
    %RECORDING Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        AmplitudeScale
        Eventstream
        IsTrainingRecording
        Center
        Left
        Right
    end
    
    methods
        function obj = Recording(name, isTrainingRecording)
            %RECORDING Construct all the objects
            %   super detailed
            obj.Eventstream = name;
            obj.IsTrainingRecording = isTrainingRecording;
            obj.Center = Blinks;
            obj.Left = Blinks;
            obj.Right = Blinks;
        end
        
        function [centerAverageOn, centerAverageOff] = getcenteraverages(obj, blinkLength)
            [centerAverageOn, centerAverageOff] = obj.Center.getaverages(obj.AmplitudeScale, obj.Eventstream, blinkLength);
        end
        
        function [centerSigmaOn, centerSigmaOff] = getcentersigmas(obj, blinkLength)
            [centerSigmaOn, centerSigmaOff] = obj.Center.getsigmas(obj.AmplitudeScale, obj.Eventstream, blinkLength);
        end
        
        function [leftAverageOn, leftAverageOff] = getleftaverages(obj, blinkLength)
            [leftAverageOn, leftAverageOff] = obj.Left.getaverages(obj.AmplitudeScale, obj.Eventstream, blinkLength);
        end
        
        function [rightAverageOn, rightAverageOff] = getrightaverages(obj, blinkLength)
            [rightAverageOn, rightAverageOff] = obj.Right.getaverages(obj.AmplitudeScale, obj.Eventstream, blinkLength);
        end
        
        function [modelOn, modelOff, varianceOn, varianceOff] = getmodelblink(obj, blinkLength)
            [centerOn, centerOff] = obj.getcenteraverages(blinkLength);
            [leftOn, leftOff] = obj.getleftaverages(blinkLength);
            [rightOn, rightOff] = obj.getrightaverages(blinkLength);
            modelOn = (centerOn + leftOn + rightOn) / 3;
            modelOff = (centerOff + leftOff + rightOff) / 3;
            varianceOn = ((centerOn - modelOn).^2  + (leftOn - modelOn).^2 + (rightOn - modelOn).^2 ) / 3;
            varianceOff = ((centerOff - modelOff).^2 + (leftOff - modelOff).^2 + (rightOff - modelOff).^2) / 3;
        end
        
    end
end


