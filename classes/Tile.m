classdef Tile < handle
    properties
        ActivityOn = 1
        ActivityOff = 1
        AllTimestamps
        BlinkLength
        GrowConstant
        BufferOn
        BufferOnStart = 1
        BufferOff
        BufferOffStart = 1
        LastPM = 0
        LastOn = 0
        LastOff = 0
        MinimumDifference
        DelayConstant
    end
    
    methods
        function obj = Tile()
        end
        
        function initialise(obj, timeconst, growConst, allts, blinklength)
            obj.AllTimestamps = allts;
            obj.BlinkLength = blinklength;
            obj.GrowConstant = growConst;
            obj.DelayConstant = timeconst;
            obj.BufferOn = zeros(1, length(allts));
            obj.BufferOff = zeros(1, length(allts));
            obj.MinimumDifference = blinklength / 10;
        end
        
        function updateactivity(obj, timestamp, polarity, growConst)
            if polarity == 1
                obj.ActivityOn = obj.ActivityOn * exp(-(timestamp-obj.LastOn)/obj.DelayConstant)  + 1/growConst;
                obj.LastOn = timestamp;
            else
                obj.ActivityOff = obj.ActivityOff * exp(-(timestamp-obj.LastOff)/obj.DelayConstant)  + 1/growConst;
                obj.LastOff = timestamp;
            end
        end
        
        function [numOn, numOff] = updatebuffer(obj, i, timestamp, polarity)
            if polarity == 1
                obj.BufferOn(i) = 1;
            else
                obj.BufferOff(i) = 1;
            end
            for j = obj.BufferOnStart:(i-1)
                if obj.AllTimestamps(j) < (timestamp - obj.BlinkLength)
                    obj.BufferOn(j) = 0;
                else
                    obj.BufferOnStart = j;
                    break;
                end
            end
            for j = obj.BufferOffStart:(i-1)
                if obj.AllTimestamps(j) < (timestamp - obj.BlinkLength)
                    obj.BufferOff(j) = 0;
                else
                    obj.BufferOffStart = j;
                    break;
                end
            end
            if timestamp - obj.LastPM >= obj.MinimumDifference
                numOn = nnz(obj.BufferOn(obj.BufferOnStart:i));
                numOff = nnz(obj.BufferOff(obj.BufferOffStart:i));
            else
                [numOn, numOff] = deal(0);
            end
        end
    end
end

