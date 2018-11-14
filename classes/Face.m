classdef Face < handle
    properties
        Blinks = Blink.empty
        Blobs = Blob.empty
        BlinkIndex = 1
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
        
        function pos = gettrackerpositions(obj)
            pos = [obj.Blobs(1).x , obj.Blobs(1).y; obj.Blobs(2).x, obj.Blobs(2).y];
        end
        
        function times = getblinktimes(obj)
            times = zeros(1, length(obj.Blinks));
            for t = 1:length(obj.Blinks)
                times(t) = obj.Blinks(t).ts;
            end
        end
        
        function res = checkreset(obj, timestamp)
            res = false;
            if obj.BlinkIndex <= length(obj.Blinks) && timestamp > obj.Blinks(obj.BlinkIndex).ts
                obj.resettracker(obj.Blinks(obj.BlinkIndex));
                obj.BlinkIndex = obj.BlinkIndex + 1;
                res = true;
            end
        end
        
        function resettracker(obj, blink)
            obj.Blobs = Blob(blink.x1, blink.y1, 3, 0, 2);
            obj.Blobs(2) = Blob(blink.x2, blink.y2, 3, 0, 2);
        end
        
        function probability = getmaxtrackerprobability(obj)
            probability = 0;
            for b = 1:length(obj.Blobs)
                if obj.Blobs(b).getblobprobability > probability
                    probability = obj.Blobs(b).getblobprobability;
                end
            end
        end
    end
end

