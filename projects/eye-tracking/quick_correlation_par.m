function eye = quick_correlation_par(eye, filterOn, filterOff, amplitudeScale, slidingWindowWidth, corrBufferScale)
% apply sliding window on eventstream and store correlation results in
% substructure

allTimestamps = eye.ts;
allActivityOn = eye.activityOn;
allActivityOff = eye.activityOff;
len = length(allTimestamps);

minimumDifference = slidingWindowWidth/10;
bufferSize = slidingWindowWidth/corrBufferScale;

if allTimestamps(end) < 10000
    return;
end

cores = 48;
sequence = int32(len/cores)-1;
correlations = nan(cores, sequence);

parfor c = 1:cores
    sliceStart = (c-1) * sequence + 1;
    newAllTimestamps = allTimestamps;
    newAllActivityOff = allActivityOff;
    newAllActivityOn = allActivityOn;
    sliceStartTimestamp = newAllTimestamps(sliceStart);
    bufferOn = zeros(1, len);
    bufferOff = bufferOn;
    numBufferOn = 0;
    numBufferOff = numBufferOn;
    windowStart = find(newAllTimestamps > (sliceStartTimestamp - slidingWindowWidth));
    windowStart = windowStart(1);
    for b = windowStart:sliceStart
        if isnan(newAllActivityOff(b))
            bufferOn(b) = 1;
            numBufferOn = numBufferOn + 1;
        else
            bufferOff(b) = 1;
            numBufferOff = numBufferOff + 1;
        end 
    end
    lastPM = 0;
    bufferOnStart = windowStart;
    bufferOffStart = bufferOnStart;
    disp("Hello from thread number " + num2str(c) + ", I'm slicing at " + num2str(sliceStartTimestamp/1000000) + "s.")
    half = round(sequence/2);
    quarter = round(sequence/4);
    for l = 1:sequence
        if l == quarter
            disp("Thread " + num2str(c) + " reporting quarter way done!")
        end
        if l == half
            disp("Thread " + num2str(c) + " reporting half way done!")
        end
        i = (c-1) * sequence + l;
        timestamp = newAllTimestamps(i);
        % add latest event to the buffer
        if isnan(newAllActivityOff(i))
            bufferOn(i) = 1;
            numBufferOn = numBufferOn + 1;
        else
            bufferOff(i) = 1;
            numBufferOff = numBufferOff + 1;
        end
        % remove events from buffer that are outside sliding window
        for j = bufferOnStart:(i-1)
            if newAllTimestamps(j) < (timestamp - slidingWindowWidth)
                if bufferOn(j) == 1
                    bufferOn(j) = 0;
                    numBufferOn = numBufferOn - 1;
                end
            else
                bufferOnStart = j;
                break;
            end
        end
        for j = bufferOffStart:(i-1)
            if newAllTimestamps(j) < (timestamp - slidingWindowWidth)
                if bufferOff(j) == 1
                    bufferOff(j) = 0;
                    numBufferOff = numBufferOff - 1;
                end
            else
                bufferOffStart = j;
                break;
            end
        end

        if timestamp - lastPM >= minimumDifference && timestamp > slidingWindowWidthq
            if numBufferOn > amplitudeScale/2 && numBufferOn < 10*amplitudeScale/2
                if  numBufferOff > amplitudeScale/3 && numBufferOff < 10*amplitudeScale/2
                    bufOn = zeros(1, slidingWindowWidth/corrBufferScale);
                    bufOff = zeros(1, slidingWindowWidth/corrBufferScale);
                    windowTimeStart = timestamp - slidingWindowWidth;
                    % generate a 'time representation' rather than simply the events
                    % and downscale to smaller buffer size
                    for k=find(bufferOn == 1)
                        index = ceil((newAllTimestamps(k) - windowTimeStart)/corrBufferScale);
                        if index == 0
                            index = 1;
                        end
                        bufOn(index) = newAllActivityOn(k);
                    end
                    m = max(bufOn(1:floor((slidingWindowWidth/corrBufferScale)/3)));
                    if m < 0.6 || m > 1.6
                        continue
                    end
                    for k=find(bufferOff == 1)
                        index = ceil((newAllTimestamps(k) - windowTimeStart)/corrBufferScale);
                        if index == 0
                            index = 1;
                        end
                        bufOff(index) = newAllActivityOff(k);
                    end
                    samplesOn = filterOn .* (bufOn>0);
                    samplesOff = filterOff .* (bufOff>0);
                    resOn = xcorr(bufOn, samplesOn, 'coeff');
                    resOff = xcorr(bufOff, samplesOff, 'coeff');
                    correlations(c, l) = 1.25*resOn(bufferSize) * 0.8*resOff(bufferSize);
                    lastPM = timestamp;
                end
            end
        end
    end
end
correlations = reshape(correlations', 1, []);
for i = length(correlations):length(allTimestamps)
    correlations(i) = NaN;
end
eye.patternCorrelation = correlations;

end