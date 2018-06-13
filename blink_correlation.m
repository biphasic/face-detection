%%run blink_extractor first to have access to eye vars

%hold on
%on = stem(eye.ts, eye.activityOn)
%on.Color = 'blue';
%off = stem(eye.ts, eye.activityOff)
%off.Color = 'red';
eye.PMindicators = zeros(1, length(eye.ts));

slidingWindowWidth = 400000;
bufferScale = 100;
bufferSize = slidingWindowWidth/bufferScale;
minimumDifference = slidingWindowWidth/2;
index = 1;
newIndex = 1;
lastTS = 0;
lastPM = 0;
buffer = circVBuf(int64(bufferSize), int64(1), 1);

%loop over every event
for i = 1:10%length(eye.ts)
    diff = eye.ts(i) - lastTS;
    lastTS = eye.ts(i);
    if diff / slidingWindowWidth > 1 %haven't received an event for at least one slidingWindow length
        buffer = circVBuf(int64(bufferSize), int64(1), 1);
        index = floor(mod(slidingWindowWidth, diff)/bufferScale);
    else
        newIndex = floor(diff/bufferScale)+index;
        newIndex = mod(newIndex, bufferSize);
        for i=index:newIndex-2
            buffer(i) = 0;
        end
        if ~isnan(eye.activityOn(i))
            buffer(newIndex) = eye.activityOn(i);
        else
            buffer(newIndex) = 10;
        end
        index = newIndex;
    end
    
    if eye.ts(i) - lastPM >= minimumDifference
        lastPM = eye.ts(i);
        eye.PMindicators(i) = 1;
    end 
end