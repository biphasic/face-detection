%%run blink_extractor first to have access to eye vars

%hold on
%on = stem(eye.ts, eye.activityOn)
%on.Color = 'blue';
%off = stem(eye.ts, eye.activityOff)
%off.Color = 'red';
eye.PMindicators = nan(1, length(eye.ts));
eye.NumberOfEvents = nan(1, length(eye.ts));

slidingWindowWidth = 400000;
bufferScale = 100;
bufferSize = slidingWindowWidth/bufferScale;
minimumDifference = slidingWindowWidth/2;
index = 1;
newIndex = 1;
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
    if eye.ts(i) - lastPM >= minimumDifference && numberOfEventsWithinWindow > 30 && numberOfEventsWithinWindow < 300
        lastPM = eye.ts(i);
        eye.PMindicators(i) = 1;

        eye.NumberOfEvents(i) = numberOfEventsWithinWindow;
    end 
end

windows = eye.ts(eye.PMindicators==1);
disp('number of windows: ')
length(windows)
stem(eye.ts, eye.activityOn/amplitudeScale);
hold on
stem(eye.ts, eye.activityOff/amplitudeScale);
odd = 1;
for i=eye.ts(eye.PMindicators==1)
    temp = eye.NumberOfEvents(eye.ts == i)/100;
    plot([i i], [0 temp(~isnan(temp))]);
    stem(i, temp(~isnan(temp)));
    odd = odd + 1;
    odd = mod(odd, 2);
    if odd
        a = area([i-slidingWindowWidth i], [1 1]);
    else
        a = area([i-slidingWindowWidth i], [1.1 1.1]);
    end
    a.FaceAlpha = 0.3;
end
