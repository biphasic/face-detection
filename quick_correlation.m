function eye = quick_correlation(eye, filterOn, filterOff, amplitudeScale, slidingWindowWidth)
% apply sliding window on eventstream and store correlation results in
% substructure

allTimestamps = eye.ts;
allActivityOn = eye.activityOn;
allActivityOff = eye.activityOff;
len = length(allTimestamps);
eye.patternCorrelation = nan(1, len);

minimumDifference = slidingWindowWidth/10;
corrBufferScale = 10000;
bufferSize = slidingWindowWidth/corrBufferScale;

filterOn = resample(filterOn, 1, 100);
filterOff = resample(filterOff, 1, 100);
sumFilterOn = sum(filterOn);
sumFilterOff = sum(filterOff);

bufferOn = zeros(1, length(allActivityOn));
bufferOff = zeros(1, length(allActivityOn));
skip = find(allTimestamps > 500000);
if ~isempty(skip)
    skip = skip(1);
else
    return;
end

bufferOnStart = skip;
bufferOffStart = skip;
lastPM = 0;

%loop over all events
for i = skip:len
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
                % generate a 'time representation' rather than simply the events
                % and downscale to smaller buffer size
                start = max(bufferOnStart, bufferOffStart)-1;
                mask = start:i;
                %[~, aOn, aOff] = quick_shannonise(eye.ts(mask), eye.p(mask), eye.activityOn(mask), eye.activityOff(mask), corrBufferScale);
                blink.ts = eye.ts(mask);
                blink.p = eye.p(mask);
                blink.activityOn = eye.activityOn(mask);
                blink.activityOff = eye.activityOff(mask);
                blink = shannonise(blink, 50000, 10000);
                try
                    %activityOn = aOn(end-bufferSize:end)/amplitudeScale;
                    %activityOff = aOff(end-bufferSize:end)/amplitudeScale;
                    activityOn = blink.activityOn(end-(bufferSize-1):end)/amplitudeScale;
                    activityOff = blink.activityOff(end-(bufferSize-1):end)/amplitudeScale;
                catch
                    disp('ups')
                    continue
                end
                sumActivityOn = sum(activityOn);
                sumActivityOff = sum(activityOff);
                if sumActivityOn < sumFilterOn * 0.75 || sumActivityOn > sumFilterOn * 1.25 || sumActivityOff < sumFilterOff * 0.8 || sumActivityOff > sumFilterOff * 1.2
                    continue
                end
                    
                resOn = xcorr(activityOn, filterOn, 'coeff');
                resOff = xcorr(activityOff, filterOff, 'coeff');
                eye.patternCorrelation(i) = 1.25*resOn(bufferSize) * 0.8*resOff(bufferSize);
                lastPM = timestamp;
            end
        end
    end
end

end