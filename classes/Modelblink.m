classdef Modelblink
    %MODELBLINK Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        AverageOn
        AverageOff
        VarianceOn
        VarianceOff
    end
    
    methods
        %no functions
        function obj = Modelblink()
        end
        
        function r = plus(obj1, obj2)
            properties = fieldnames(obj1);
            r = Modelblink();
            %r.AverageOn = obj1.AverageOn + obj2.AverageOn;
            %r.AverageOff = obj1.AverageOff + obj2.AverageOff;
            %r.VarianceOn = (obj1.VarianceOn - obj2.VarianceOn).^2;
            %r.VarianceOff = (obj1.VarianceOff - obj2.VarianceOff).^2;
            for p = 1:numel(properties)
                r.(properties{p}) = obj1.(properties{p}) + obj2.(properties{p});
            end
        end
        
        function r = mrdivide(obj, div)
            properties = fieldnames(obj);
            r = Modelblink();
            for p = 1:numel(properties)
                r.(properties{p}) = obj.(properties{p}) / div;
            end
        end
    end
end

