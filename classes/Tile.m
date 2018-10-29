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
        
        function [numOff] = updatebuffer(obj, i, timestamp, polarity, growconst)
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
            numOff = 0;
            if timestamp - obj.LastPM >= obj.MinimumDifference
                numOn = nnz(obj.BufferOn(obj.BufferOnStart:i));
                if numOn > growconst/2 && numOn < 5*growconst
                    numOff = nnz(obj.BufferOff(obj.BufferOffStart:i));

                end
            end
        end
        
        function correlation(obj, modelblink, corrbufferscale)
            bufOn = zeros(1, obj.BlinkLength/corrbufferscale);
            bufOff = zeros(1, obj.BlinkLength/corrbufferscale);
            divisor = timestamp - obj.BlinkLength;
            % generate a 'time representation' rather than simply the events
            % and downscale to smaller buffer size
            for k=find(obj.BufferOn == 1)
                index = ceil(mod(obj.AllTimestamps(k), divisor)/corrbufferscale);
                if index == 0
                    index = 1;
                end
                bufOn(index) = allActivityOn(k)/amplitudeScale;
            end
            m = max(bufOn(1:floor((obj.BlinkLength/corrbufferscale)/3)));
            if m < 0.6 || m > 1.6
                return
            end
            for k=find(bufferOff == 1)
                index = ceil(mod(allTimestamps(k), divisor)/corrbufferscale);
                if index == 0
                    index = 1;
                end
                bufOff(index) = allActivityOff(k)/amplitudeScale;
            end
            samplesOn = modelblink.AverageOn .* (bufOn>0);
            samplesOff = modelblink.AverageOff .* (bufOff>0);
            resOn = xcorr(bufOn, samplesOn, 'coeff');
            resOff = xcorr(bufOff, samplesOff, 'coeff');
            eye.patternCorrelation(i) = 1.25*resOn(bufferSize) * 0.8*resOff(bufferSize);
            lastPM = timestamp;
        end
    end
end

