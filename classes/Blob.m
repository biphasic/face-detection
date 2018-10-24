classdef Blob
    properties
        x
        y
        sigmaX
        sigmaXY
        sigmaY
    end
    
    methods
        function obj = Blob(x, y, sigmaX, sigmaXY, sigmaY)
            obj.x = x;
            obj.y = y;
            obj.sigmaX = sigmaX;
            obj.sigmaXY = sigmaXY;
            obj.sigmaY = sigmaY;
        end
        
        function updatebyevent(obj)
            
        end
    end
end

