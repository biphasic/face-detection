classdef Subject < handle
    %SUBJECT Summary of this class goes here
    %   Detailed explanation goes here
    
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
        
        function obj = addrecording(obj, number, rec)
            obj.Recordings{1,number} = rec;
        end
    end
    
end



