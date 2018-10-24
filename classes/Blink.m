classdef Blink    
    properties
        x1
        y1
        x2
        y2
        ts
    end
    
    methods
        function obj = Blink(x1, y1, x2, y2, t)
            obj.x1 = x1;
            obj.y1 = y1;
            obj.x2 = x2;
            obj.y2 = y2;
            obj.ts = t;
        end
    end
end

