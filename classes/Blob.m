classdef Blob < handle
    properties
        x
        y
        sigmaX
        sigmaXY
        sigmaY
        positionInertia = 0.9
        varianceInertia = 0.9999
        minimumProbability = 0.003
    end
    
    methods
        function obj = Blob(x, y, sigmaX, sigmaXY, sigmaY)
            obj.x = x;
            obj.y = y;
            obj.sigmaX = sigmaX;
            obj.sigmaXY = sigmaXY;
            obj.sigmaY = sigmaY;
        end
        
        function probability = getblobprobability(obj, x, y)
            xDelta = x - obj.x;
            yDelta = y - obj.y;
            determinant = obj.sigmaX * obj.sigmaY - obj.sigmaXY^2;
            probability = exp(-(xDelta^2 * obj.sigmaY + yDelta^2 * obj.sigmaX - 2 * xDelta * yDelta * obj.sigmaXY)/(2*determinant))/sqrt(determinant);
            probability = probability / (2*pi);
        end
        
        function updatebyevent(obj, x, y)
            obj.x = obj.positionInertia * obj.x + (1 - obj.positionInertia) * x;
            obj.y = obj.positionInertia * obj.y + (1 - obj.positionInertia) * y;
        end
    end
end

