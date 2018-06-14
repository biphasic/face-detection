%%run blink_extractor first to have access to eye vars

%hold on
%on = stem(eye.ts, eye.activityOn)
%on.Color = 'blue';
%off = stem(eye.ts, eye.activityOff)
%off.Color = 'red';
eye.PatternCorrelation = nan(1, length(eye.ts));
eye.NumberOfEvents = nan(1, length(eye.ts));

slidingWindowWidth = 400000;
bufferScale = 100;
bufferSize = slidingWindowWidth/bufferScale;
minimumDifference = slidingWindowWidth/4;
lastTS = 0;
lastPM = 0;
buffer = circVBuf(int64(bufferSize), int64(1), 0);

%loop over every event
for i = 1:length(eye.ts)
    diff = eye.ts(i) - lastTS;
    if diff / slidingWindowWidth > 1 %haven't received an event for at least one slidingWindow length
        buffer.clear
    else
        limit = floor((eye.ts(i)-lastTS)/bufferScale);
        for u=1:limit
            buffer.append(0);
        end
    end
    if i ~= 1 && floor((eye.ts(i)-eye.ts(i-1))/bufferScale) > 0
        if ~isnan(eye.activityOn(i)) 
            buffer.append(eye.activityOn(i));
        else
            buffer.append(0);
        end
    end
    lastTS = eye.ts(i);
    
    numberOfEventsWithinWindow = buffer.raw(buffer.fst:buffer.lst);
    numberOfEventsWithinWindow = length(numberOfEventsWithinWindow(numberOfEventsWithinWindow > 0));
    if eye.ts(i) - lastPM >= minimumDifference && numberOfEventsWithinWindow > 60 && numberOfEventsWithinWindow < 300
        buf = buffer.raw(buffer.fst:buffer.lst)' / amplitudeScale;
        if length(buf) < bufferSize
            zeroedBuf = zeros(1,bufferSize);
            zeroedBuf(end-length(buf)+1:end) = buf;
            buf = zeroedBuf;
        end
        samples = filteredAverageOn .* (buf>0);
        res = xcorr(buf, samples, 'coeff');
        lastPM = eye.ts(i);
        eye.PatternCorrelation(i) = res(bufferSize);
        eye.NumberOfEvents(i) = numberOfEventsWithinWindow;
    end 
end

windows = eye.ts(~isnan(eye.PatternCorrelation));
disp('number of windows: ')
length(windows)
stem(eye.ts, eye.activityOn/amplitudeScale);
hold on
stem(eye.ts, eye.activityOff/amplitudeScale);
for i=eye.ts(~isnan(eye.PatternCorrelation))
    temp = eye.NumberOfEvents(eye.ts == i)/100;
    plot([i i], [0 temp(~isnan(temp))]);
    stem(i, temp(~isnan(temp)));
    a = area([i-slidingWindowWidth i], [eye.PatternCorrelation(eye.ts == i) eye.PatternCorrelation(eye.ts == i)]);
    a.FaceAlpha = 0.3;
end
