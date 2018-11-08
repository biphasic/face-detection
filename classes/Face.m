classdef Face < handle
    properties
        Blinks = Blink.empty
        Blobs
    end
    
    properties (Dependent = true)
        Center
    end
    
    methods
        function obj = Face()
        end
        
        function center = get.Center(obj)
            if ~isempty(obj.Blobs)
                center = [(obj.Blobs(1).x + obj.Blobs(2).x)/2 , (obj.Blobs(1).y + obj.Blobs(2).y)/2];
            else
                center = 0;
            end
        end
        
        function addblink(obj, blink)
            l = length(obj.Blinks)+1;
            obj.Blinks(l) = blink;
        end
    end
end

