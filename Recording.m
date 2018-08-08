classdef Recording < handle
    %RECORDING Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        AmplitudeScale
        Blinks
        Eventstream
        IsTrainingRecording
    end
    
    methods
        function obj = Recording(name, isTrainingRecording)
            %RECORDING Construct all the objects
            %   super detailed
            obj.Eventstream = name;
            obj.IsTrainingRecording = isTrainingRecording;
        end
        
        function res = testfunction(~, number)
            res = number;
        end
    end
end


