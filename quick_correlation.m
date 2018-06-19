slidingWindowWidth = 400000;
minimumDifference = slidingWindowWidth/8;
correlationThreshold = 0.88;

bufferOn = zeros(1, length(eye.activityOn));
bufferOff = zeros(1, length(eye.activityOn));
bufferOnStart = 2760;
bufferOffStart = 2760;
lastPM = 0;
columns = 0;

stem(eye.ts, eye.activityOn/amplitudeScale);
hold on;
%stem(eye.ts

tic
for i = 2760:length(eye.ts)
    timestamp = eye.ts(i);
    if isnan(eye.activityOff(i))
        bufferOn(i) = 1;
    else
        bufferOff(i) = 1;
    end
    for j = bufferOnStart:(i-1)%find(bufferOn == 1)
        if eye.ts(j) < (timestamp - slidingWindowWidth)
            bufferOn(j) = 0;
        else
            bufferOnStart = j;
            break;
        end
    end
    for j = bufferOffStart:(i-1)%find(bufferOn == 1)
        if eye.ts(j) < (timestamp - slidingWindowWidth)
            bufferOff(j) = 0;
        else
            bufferOffStart = j;
            break;
        end
    end
    
    n = nnz(bufferOn) + nnz(bufferOff);
    if timestamp - lastPM >= minimumDifference && n > 50 && n < 300
        sampleOn = zeros(1, slidingWindowWidth/100);
        for k=find(bufferOn == 1)
            index = floor(mod(eye.ts(k), slidingWindowWidth)/100);
            sampleOn(index) = eye.activityOn(k)/amplitudeScale;
        end
        %stem(eye.ts(bufferOn == 1), -eye.activityOn(bufferOn == 1)/amplitudeScale)
        stem(timestamp-slidingWindowWidth+bufferScale:bufferScale:timestamp, -sampleOn)
        stem(timestamp, n/100)
        lastPM = timestamp
        columns = columns + 1
    end
end
toc