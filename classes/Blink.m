classdef Blink    
    properties
        LeftEyeX
        LeftEyeY
        RightEyeX
        RightEyeY
        Timestamp
    end
    
    methods
        function obj = Blink(x1, y1, x2, y2, t)
            obj.LeftEyeX = x1;
            obj.LeftEyeY = y1;
            obj.RightEyeX = x2;
            obj.RightEyeY = y2;
            obj.Timestamp = t;
        end
    end
end

