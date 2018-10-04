classdef Subject < handle
    properties
        Name
        Recordings
        CorrelationThreshold
        Modelblink
        AmplitudeScale
        BlinkLength
    end
        
    methods
        function obj = Subject(name)
            obj.Name = name;
            obj.CorrelationThreshold = 0.88;
            obj.Modelblink = Modelblink();
            obj.BlinkLength = 300000;
        end
        
        function obj = addrecording(obj, number, eventStream, isTrainingRecording)
            obj.Recordings{1,number} = Recording(eventStream, isTrainingRecording, obj);
        end
    end
    
end