classdef Subject < handle
    %SUBJECT Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Name
        Recordings
    end
        
    methods
        function obj = Subject(name)
            obj.Name = name;
        end
        
        function obj = addrecording(obj, number, rec)
            if isempty(obj.Recordings)
                obj.Recordings = rec;
                for i = 1:number
                    obj.Recordings(1,i) = rec;
                end
            else
                obj.Recordings(1,number) = rec;
            end
        end
    end
    
end



