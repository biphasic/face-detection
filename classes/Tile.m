classdef Tile < handle
    properties
        ActivityOn
        ActivityOff
        AddConstant
        BufferOn
        BufferOnStart = 1
        BufferOff
        BufferOffStart = 1
        LastPM = 0
        LastOn = 0
        LastOff = 0
        DelayConstant
    end
    
    methods
        function obj = Tile(timeconst, addConst, reclength)
            obj.ActivityOn = addConst;
            obj.ActivityOff = addConst;
            obj.AddConstant = addConst;
            obj.DelayConstant = timeconst;
            obj.BufferOn = zeros(1, reclength);
            obj.BufferOff = zeros(1, reclength);
        end
        
        function updateactivity(obj, timestamp, polarity, addconst)
            if polarity == 1
                obj.ActivityOn = obj.ActivityOn * exp(-(timestamp-obj.LastOn)/obj.DelayConstant)  + addconst;
            else
                obj.ActivityOff = obj.ActivityOff * exp(-(timestamp-obj.LastOff)/obj.DelayConstant)  + addconst;
            end
        end
        
        function [numOn, numOff] = updatebuffer(obj, i, timestamp)
            for j = obj.BufferOnStart:(i-1)
                if allTimestamps(j) < (timestamp - slidingWindowWidth)
                    obj.BufferOn(j) = 0;
                else
                    obj.BufferOnStart = j;
                    break;
                end
            end
            for j = obj.BufferOffStart:(i-1)
                if allTimestamps(j) < (timestamp - slidingWindowWidth)
                    obj.BufferOff(j) = 0;
                else
                    obj.BufferOffStart = j;
                    break;
                end
            end
        end
    end
end

