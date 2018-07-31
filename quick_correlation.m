function eye = quick_correlation(eye, amplitudeScale)

eye.patternCorrelation = nan(1, length(eye.ts));

slidingWindowWidth = 400000;
minimumDifference = slidingWindowWidth/8;
corrBufferScale = 100;
bufferSize = slidingWindowWidth/corrBufferScale;
%correlationThreshold = 0.88;

load('averages', 'filteredAverageOn', 'filteredAverageOff');

bufferOn = zeros(1, length(eye.activityOn));
bufferOff = zeros(1, length(eye.activityOn));
skip = find(eye.ts > 1000000);
if ~isempty(skip)
    skip = skip(1);    
else
    skip = find(eye.ts == eye.ts(end));
end

bufferOnStart = skip;
bufferOffStart = skip;
lastPM = 0;
%columns = 0;

%stem(eye.ts, eye.activityOn/amplitudeScale);
%hold on;
%stem(eye.ts, -eye.activityOff/amplitudeScale);
%plot([0 eye.ts(end)], [correlationThreshold correlationThreshold]);

%tic
%loop over all events
for i = skip:length(eye.ts)
    timestamp = eye.ts(i);
    % add latest event to the buffer
    if isnan(eye.activityOff(i))
        bufferOn(i) = 1;
    else
        bufferOff(i) = 1;
    end
    % remove events from buffer that are outside sliding window
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
            if index == 0
                index = 1;
            end
            bufOn(index) = eye.activityOn(k)/amplitudeScale;
        end
        for k=find(bufferOff == 1)
            index = ceil(mod(eye.ts(k), divisor)/corrBufferScale);
            if index == 0
                index = 1;
            end
            bufOff(index) = eye.activityOff(k)/amplitudeScale;
        end
        samplesOn = filteredAverageOn .* (bufOn>0);
        samplesOff = filteredAverageOff .* (bufOff>0);
        resOn = xcorr(bufOn, samplesOn, 'coeff');
        resOff = xcorr(bufOff, samplesOff, 'coeff');
        eye.patternCorrelation(i) = resOn(bufferSize)*resOff(bufferSize);
        %stem(timestamp-slidingWindowWidth+bufferScale:bufferScale:timestamp, -bufOn)
        %stem(timestamp, n/100)
        lastPM = timestamp;
        %columns = columns + 1
    end
    %t = t+toc;
end
%toc

%windows = eye.ts(~isnan(eye.patternCorrelation));
%disp('number of windows: ')
%length(windows)
%for i=eye.ts(~isnan(eye.patternCorrelation))
%    a = area([i-slidingWindowWidth i], [eye.patternCorrelation(eye.ts == i) eye.patternCorrelation(eye.ts == i)]);
%    a.FaceAlpha = 0.3;
%    if eye.patternCorrelation(eye.ts == i) > correlationThreshold
%        a.FaceColor = 'yellow';
%        a.FaceAlpha = 0.7;
%    end
%end

end