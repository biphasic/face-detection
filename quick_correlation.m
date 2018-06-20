eye.PatternCorrelation = nan(1, length(eye.ts));

slidingWindowWidth = 400000;
minimumDifference = slidingWindowWidth/8;
correlationThreshold = 0.88;

bufferOn = zeros(1, length(eye.activityOn));
bufferOff = zeros(1, length(eye.activityOn));
skip = find(eye.ts > 1000000);
skip = skip(1);
bufferOnStart = skip;
bufferOffStart = skip;
corrBufferScale = 100;
lastPM = 0;
columns = 0;

stem(eye.ts, eye.activityOn/amplitudeScale);
hold on;
stem(eye.ts, -eye.activityOff/amplitudeScale);
plot([0 eye.ts(end)], [correlationThreshold correlationThreshold]);

tic
%loop over all events
for i = skip:length(eye.ts)
    timestamp = eye.ts(i);
    % add latest event to the buffer
    if isnan(eye.activityOff(i))
        bufferOn(i) = 1;
    else
        bufferOff(i) = 1;
    end
    % remove events from buffer that are outside slinding window
    for j = bufferOnStart:(i-1)
        if eye.ts(j) < (timestamp - slidingWindowWidth)
            bufferOn(j) = 0;
        else
            bufferOnStart = j;
            break;
        end
    end
    for j = bufferOffStart:(i-1)
        if eye.ts(j) < (timestamp - slidingWindowWidth)
            bufferOff(j) = 0;
        else
            bufferOffStart = j;
            break;
        end
    end
    
    % check sum of ON/OFF events within buffers
    n = nnz(bufferOn) + nnz(bufferOff);
    %tic
    if timestamp - lastPM >= minimumDifference && n > 50 && n < 300
        bufOn = zeros(1, slidingWindowWidth/corrBufferScale);
        bufOff = zeros(1, slidingWindowWidth/corrBufferScale);
        divisor = timestamp - slidingWindowWidth;
        % generate a 'time representation' rather than simply the events
        % and downscale to smaller buffer size
        for k=find(bufferOn == 1)
            index = ceil(mod(eye.ts(k), divisor)/corrBufferScale);
            bufOn(index) = eye.activityOn(k)/amplitudeScale;
        end
        for k=find(bufferOff == 1)
            index = ceil(mod(eye.ts(k), divisor)/corrBufferScale);
            bufOff(index) = eye.activityOff(k)/amplitudeScale;
        end
        samplesOn = filteredAverageOn .* (bufOn>0);
        samplesOff = filteredAverageOff .* (bufOff>0);
        resOn = xcorr(bufOn, samplesOn, 'coeff');
        resOff = xcorr(bufOff, samplesOff, 'coeff');
        eye.PatternCorrelation(i) = resOn(bufferSize)*resOff(bufferSize);
        %stem(timestamp-slidingWindowWidth+bufferScale:bufferScale:timestamp, -bufOn)
        stem(timestamp, n/100)
        lastPM = timestamp
        columns = columns + 1
    end
    %t = t+toc;
end
toc

windows = eye.ts(~isnan(eye.PatternCorrelation));
disp('number of windows: ')
length(windows)
for i=eye.ts(~isnan(eye.PatternCorrelation))
    a = area([i-slidingWindowWidth i], [eye.PatternCorrelation(eye.ts == i) eye.PatternCorrelation(eye.ts == i)]);
    a.FaceAlpha = 0.3;
    if eye.PatternCorrelation(eye.ts == i) > correlationThreshold
        a.FaceColor = 'yellow';
        a.FaceAlpha = 0.7;
    end
end