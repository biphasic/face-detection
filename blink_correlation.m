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
minimumDifference = slidingWindowWidth/2;
lastOnTS = 0;
lastOffTS = 0;
lastTS = 0;
lastPM = 0;
bufferOn = circVBuf(int64(bufferSize), int64(1), 0);
bufferOff = circVBuf(int64(bufferSize), int64(1), 0);
for j = 1:bufferSize
    bufferOn.append(0);
    bufferOff.append(0);
end

%loop over every event
for i = 1:length(eye.ts)
    if ~isnan(eye.activityOn(i))
        diff = eye.ts(i) - lastOnTS;
        if diff / slidingWindowWidth > 1 %haven't received an event for at least one slidingWindow length
            bufferOn.clear
            for q=1:bufferSize
                bufferOn.append(0);
            end
        else % fill up buffer with 0s related to how much time has passed
            limit = floor((eye.ts(i)-lastOnTS)/bufferScale); 
            for u=1:limit
                bufferOn.append(0);
            end
        end
        if floor((eye.ts(i)-lastOnTS)/bufferScale) > 0
            bufferOn.append(eye.activityOn(i));
        end
        lastOnTS = eye.ts(i);
    else
        diff = eye.ts(i) - lastOffTS;
        if diff / slidingWindowWidth > 1
            bufferOff.clear
            for q=1:bufferSize
                bufferOff.append(0);
            end
        else
            limit = floor((eye.ts(i)-lastOffTS)/bufferScale);
            for u=1:limit
                bufferOff.append(0);
            end
        end
        if floor((eye.ts(i)-lastOffTS)/bufferScale) > 0
            bufferOff.append(eye.activityOff(i));
        end
        lastOffTS = eye.ts(i);
    end
    
    bufOn = bufferOn.raw(bufferOn.fst:bufferOn.lst)';
    bufOff = bufferOff.raw(bufferOff.fst:bufferOff.lst)';
    combBuf = or(bufOn > 0, bufOff > 0);
    numberOfEventsWithinWindow = length(combBuf(combBuf == 1));
    %numberOfEventsWithinWindow = 0;
    
    if eye.ts(i)>2107000
        return
    end
    if eye.ts(i) - lastPM >= minimumDifference && numberOfEventsWithinWindow > 40 && numberOfEventsWithinWindow < 500
        buf = bufferOn.raw(bufferOn.fst:bufferOn.lst)' / amplitudeScale;
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
stem(eye.ts, -eye.activityOff/amplitudeScale);
for i=eye.ts(~isnan(eye.PatternCorrelation))
    temp = eye.NumberOfEvents(eye.ts == i)/100;
    plot([i i], [0 temp(~isnan(temp))]);
    stem(i, temp(~isnan(temp)));
    a = area([i-slidingWindowWidth i], [eye.PatternCorrelation(eye.ts == i) eye.PatternCorrelation(eye.ts == i)]);
    a.FaceAlpha = 0.3;
end
