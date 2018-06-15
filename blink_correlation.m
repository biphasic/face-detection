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
lastOnTS = eye.ts(1)-bufferScale-1;
lastOffTS = eye.ts(1)-bufferScale-1;
lastTS = eye.ts(1)-bufferScale-1;
lastPM = 0;
bufferOn = circVBuf(int64(bufferSize), int64(1), 0);
bufferOff = circVBuf(int64(bufferSize), int64(1), 0);
for j = 1:bufferSize
    bufferOn.append(0);
    bufferOff.append(0);
end

stem(eye.ts, eye.activityOn/amplitudeScale);
hold on
%stem(eye.ts, eye.activityOff/amplitudeScale);
%hold on

%loop over every event
for i = 2760:length(eye.ts)
    timestamp = eye.ts(i);
    if ~isnan(eye.activityOn(i))
        % update ON buffer
        diffOn = timestamp - lastTS;
        if diffOn / slidingWindowWidth > 1 %haven't received an event for at least one slidingWindow length
            bufferOn.clear
            for q=1:bufferSize
                bufferOn.append(0);
            end
        else % fill up buffer with 0s related to how much time has passed
            limit = floor(diffOn/bufferScale); 
            for u=1:limit
                bufferOn.append(0);
            end
        end
        % update OFF buffer, needs to be done here in order to allow
        % synchronous correlations of both ON and OFF buffers
        diffOff = timestamp - lastOffTS;
        if diffOff < slidingWindowWidth
            limit = floor(diffOn/bufferScale); 
            for u=1:limit
                bufferOff.append(0);
            end
        end
        % actually add the activity to the buffer if it appears for the
        % first time
        if floor(diffOn/bufferScale) > 0
            bufferOn.append(eye.activityOn(i));
        end
        lastOnTS = timestamp;
        lastTS = timestamp;
    else
        diffOff = timestamp - lastTS;
        if diffOff / slidingWindowWidth > 1
            bufferOff.clear
            for q=1:bufferSize
                bufferOff.append(0);
            end
        else
            limit = floor(diffOff/bufferScale);
            for u=1:limit
                bufferOff.append(0);
            end
        end
        diffOn = timestamp - lastOnTS;
        if diffOn < slidingWindowWidth
            limit = floor(diffOff/bufferScale); 
            for u=1:limit
                bufferOn.append(0);
            end
        end
        if floor(diffOff/bufferScale) > 0
            bufferOff.append(eye.activityOff(i));
        end
        lastOffTS = timestamp;
        lastTS = timestamp;
    end
    
    bufOn = bufferOn.raw(bufferOn.fst:bufferOn.lst)';
    bufOff = bufferOff.raw(bufferOff.fst:bufferOff.lst)';
    combBuf = or(bufOn > 0, bufOff > 0);
    numberOfEventsWithinWindow = length(combBuf(combBuf == 1));    
    if timestamp>10807000
        break
    end
    
    if timestamp - lastPM >= minimumDifference && numberOfEventsWithinWindow > 40 && numberOfEventsWithinWindow < 1000
        bufOn = bufOn / amplitudeScale;
        bufOff = bufOff / amplitudeScale;
        %if length(buf) < bufferSize
        %    zeroedBuf = zeros(1,bufferSize);
        %    zeroedBuf(end-length(buf)+1:end) = buf;
        %    buf = zeroedBuf;
        %end
        samples = filteredAverageOn .* (bufOn>0);
        samplesOff = filteredAverageOff .* (bufOff>0);
        res = xcorr(bufOn, samples, 'coeff');
        lastPM = timestamp;
        eye.PatternCorrelation(i) = res(bufferSize);
        eye.NumberOfEvents(i) = numberOfEventsWithinWindow;
        length(timestamp-slidingWindowWidth+bufferScale:bufferScale:timestamp)
        stem(timestamp-slidingWindowWidth+bufferScale:bufferScale:timestamp, -bufOn)
    end 
end

windows = eye.ts(~isnan(eye.PatternCorrelation));
disp('number of windows: ')
length(windows)
for i=eye.ts(~isnan(eye.PatternCorrelation))
    temp = eye.NumberOfEvents(eye.ts == i)/100;
    plot([i i], [0 temp(~isnan(temp))]);
    stem(i, temp(~isnan(temp)));
    a = area([i-slidingWindowWidth i], [eye.PatternCorrelation(eye.ts == i) eye.PatternCorrelation(eye.ts == i)]);
    a.FaceAlpha = 0.3;
end
