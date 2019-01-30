function eye = quick_correlation(eye, filterOn, filterOff, amplitudeScale, slidingWindowWidth, corrBufferScale)
% apply sliding window on eventstream and store correlation results in
% substructure

allTimestamps = eye.ts;
allActivityOn = eye.activityOn;
allActivityOff = eye.activityOff;
len = length(allTimestamps);
eye.patternCorrelation = nan(1, len);

minimumDifference = slidingWindowWidth/10;
bufferSize = slidingWindowWidth/corrBufferScale;

bufferOn = zeros(1, length(allActivityOn));
bufferOff = zeros(1, length(allActivityOn));

bufferOnStart = 1;
bufferOffStart = 1;
lastPM = 0;
numBufferOn = 0;
numBufferOff = numBufferOn;

%loop over all events
for i = 1:len
    timestamp = allTimestamps(i);
    % add latest event to the buffer
    if isnan(allActivityOff(i))
        bufferOn(i) = 1;
        numBufferOn = numBufferOn + 1;
    else
        bufferOff(i) = 1;
        numBufferOff = numBufferOff + 1;
    end
    % remove events from buffer that are outside sliding window
    for j = bufferOnStart:(i-1)
        if allTimestamps(j) < (timestamp - slidingWindowWidth)
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
        if allTimestamps(j) < (timestamp - slidingWindowWidth)
            if bufferOff(j) == 1
                bufferOff(j) = 0;
                numBufferOff = numBufferOff - 1;
            end
        else
            bufferOffStart = j;
            break;
        end
    end
 
    if timestamp - lastPM >= minimumDifference && timestamp > slidingWindowWidth
        if numBufferOn > amplitudeScale/2 && numBufferOn < 10*amplitudeScale/2
            if  numBufferOff > amplitudeScale/3 && numBufferOff < 10*amplitudeScale/2
                bufOn = zeros(1, slidingWindowWidth/corrBufferScale);
                bufOff = zeros(1, slidingWindowWidth/corrBufferScale);
                windowTimeStart = timestamp - slidingWindowWidth;
                % generate a 'time representation' rather than simply the events
                % and downscale to smaller buffer size
                for k=find(bufferOn == 1)
                    index = round((allTimestamps(k) - windowTimeStart)/corrBufferScale);
                    if index == 0
                        index = 1;
                    end
                    bufOn(index) = allActivityOn(k);
                end
                m = max(bufOn(1:floor((slidingWindowWidth/corrBufferScale)/3)));
                if m < 0.6 || m > 1.6
                    continue
                end
                for k=find(bufferOff == 1)
                    index = ceil((allTimestamps(k) - windowTimeStart)/corrBufferScale);
                    if index == 0
                        index = 1;
                    end
                    bufOff(index) = allActivityOff(k);
                end
                samplesOn = filterOn .* (bufOn>0);
                samplesOff = filterOff .* (bufOff>0);
                resOn = xcorr(bufOn, samplesOn, 'coeff');
                resOff = xcorr(bufOff, samplesOff, 'coeff');
                eye.patternCorrelation(i) = 1.25*resOn(bufferSize) * 0.8*resOff(bufferSize);
                lastPM = timestamp;
            end
        end
    end
end

end