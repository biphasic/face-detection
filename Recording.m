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
        
        function [leftAverageOn, leftAverageOff] = getleftaverages(obj, blinkLength)
            [leftAverageOn, leftAverageOff] = obj.Left.getaverages(obj.AmplitudeScale, obj.Eventstream, blinkLength);
        end
        
        function [rightAverageOn, rightAverageOff] = getrightaverages(obj, blinkLength)
            [rightAverageOn, rightAverageOff] = obj.Right.getaverages(obj.AmplitudeScale, obj.Eventstream, blinkLength);
        end
        
        function model = getmodelblink(obj, blinkLength)
            model = (obj.getcenteraverages(blinkLength) + obj.getleftaverages(blinkLength) + obj.getrightaverages(blinkLength)) / 3;
        end
        
    end
end


