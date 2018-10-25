classdef Blob < handle
    properties
        x
        y
        sigmaX
        sigmaXY
        sigmaY
        positionInertia = 0.99
        varianceInertia = 0.999
    end
    
    methods
        function obj = Blob(x, y, sigmaX, sigmaXY, sigmaY)
            obj.x = x;
            obj.y = y;
            obj.sigmaX = sigmaX;
            obj.sigmaXY = sigmaXY;
            obj.sigmaY = sigmaY;
        end
        
        function updatebyevent(obj, x, y)
            xDelta = x - obj.x;
            yDelta = y - obj.y;
            obj.x = obj.positionInertia * obj.x + (1 - obj.positionInertia) * x;
            obj.y = obj.positionInertia * obj.y + (1 - obj.positionInertia) * y;
            obj.sigmaX = obj.varianceInertia * obj.sigmaX + (1 - obj.varianceInertia) * xDelta * xDelta;
            obj.sigmaXY = obj.varianceInertia * obj.sigmaXY + (1 - obj.varianceInertia) * xDelta * yDelta;
            obj.sigmaY = obj.varianceInertia * obj.sigmaY + (1 - obj.varianceInertia) * yDelta * yDelta;
        end
    end
end

