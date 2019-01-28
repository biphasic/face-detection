function eye = quick_correlation(eye, filterOn, filterOff, amplitudeScale, slidingWindowWidth, corrBufferScale)
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

cores = 12;
%correlations = nan(cores, len);
sequence = int32(allTimestamps(end)/cores);
parfor c = 1:cores
    if c == 1
        start = 1
    else
        start = find(allTimestamps <= (c * sequence) - slidingWindowWidth);
        start = start(end)
    end
    correlations(c,:) = nan(cores, length(allTimestamps));
    stop = find(allTimestamps <= (c * sequence))
    stop = stop(end)
    lastPM = 0;
    bufferOn = zeros(1, length(allActivityOn(start:stop)));
    bufferOff = zeros(1, length(allActivityOn(start:stop)));
    bufferOnStart = start;
    bufferOffStart = start;
    for i = start:stop
        timestamp = allTimestamps(i);
        % add latest event to the buffer
        if isnan(allActivityOff(i))
            bufferOn(i) = 1;
        else
            bufferOff(i) = 1;
        end
        % remove events from buffer that are outside sliding window
        for j = bufferOnStart:(i-1)
            if allTimestamps(j) < (timestamp - slidingWindowWidth)
                bufferOn(j) = 0;
            else
                bufferOnStart = j;
                break;
            end
        end
        for j = bufferOffStart:(i-1)
            if allTimestamps(j) < (timestamp - slidingWindowWidth)
                bufferOff(j) = 0;
            else
                bufferOffStart = j;
                break;
            end
        end

        if timestamp - lastPM >= minimumDifference
            nOn = nnz(bufferOn(bufferOnStart:i));
            if nOn > amplitudeScale/2 && nOn < 10*amplitudeScale/2
                nOff = nnz(bufferOff(bufferOffStart:i));
                if  nOff > amplitudeScale/3 && nOff < 10*amplitudeScale/2
                    bufOn = zeros(1, slidingWindowWidth/corrBufferScale);
                    bufOff = zeros(1, slidingWindowWidth/corrBufferScale);
                    divisor = timestamp - slidingWindowWidth;
                    % generate a 'time representation' rather than simply the events
                    % and downscale to smaller buffer size
                    for k=find(bufferOn == 1)
                        index = ceil(mod(allTimestamps(k), divisor)/corrBufferScale);
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
                        index = ceil(mod(allTimestamps(k), divisor)/corrBufferScale);
                        if index == 0
                            index = 1;
                        end
                        bufOff(index) = allActivityOff(k);
                    end
                    samplesOn = filterOn .* (bufOn>0);
                    samplesOff = filterOff .* (bufOff>0);
                    resOn = xcorr(bufOn, samplesOn, 'coeff');
                    resOff = xcorr(bufOff, samplesOff, 'coeff');
                    correlations(c, i) = 1.25*resOn(bufferSize) * 0.8*resOff(bufferSize);
                    lastPM = timestamp;
                end
            end
        end
    end
end
eye.patternCorrelation = correlations;

end