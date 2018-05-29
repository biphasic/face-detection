function events = decay(recording, scaleFactorTime)
%DECAY Summary of this function goes here
%   Detailed explanation goes here

timeconst = 50000;
arrayLength = floor((recording.ts(end)-recording.ts(1))/scaleFactorTime/scaleFactorTime);

events.ts = zeros(1, arrayLength+1);
events.activityOn = zeros(1, arrayLength);
events.activityOff = zeros(1, arrayLength);

l = length(recording.ts);
index = 1;
factor = exp(-(scaleFactorTime * scaleFactorTime)/timeconst);
starttime = floor(recording.ts(1)/scaleFactorTime);

for event = 1:l
    rec_ts = floor(recording.ts(event)/scaleFactorTime);
    scaledTS = rec_ts - mod(rec_ts - starttime, scaleFactorTime);
    regularTS = starttime + scaleFactorTime * (index - 1);
    events.ts(index) = regularTS;
    
    valOn = events.activityOn(index);
    valOff = events.activityOff(index);
    
    while regularTS < scaledTS
        valOn = valOn * factor;
        valOff = valOff * factor;
        regularTS = regularTS + scaleFactorTime;
        events.activityOn(index) = valOn;
        events.activityOff(index) = valOff;
        events.ts(index) = regularTS;
        index = index + 1;
    end

    if recording.p(event) == 1
        events.activityOn(index) = recording.activityOn(event);
        if index > 1
            events.activityOff(index) = events.activityOff(index-1) * factor;
        end
    else
        if index > 1
            events.activityOn(index) = events.activityOn(index-1) * factor;
        end
        events.activityOff(index) = recording.activityOff(event);
    end
end