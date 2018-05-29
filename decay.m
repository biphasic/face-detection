function events = decay(recording, scaleFactorTime)
%DECAY Summary of this function goes here
%   Detailed explanation goes here

timeconst = 50000;
arrayLength = round((recording.ts(end)-recording.ts(1))/scaleFactorTime);
%if mod(recording.ts(end), scaleFactorTime) ~= 0
%    arrayLength = arrayLength + 1;
%end

events.ts = zeros(1, arrayLength);
events.activityOn = zeros(1, arrayLength);
events.activityOff = zeros(1, arrayLength);

l = length(recording.ts);
lastScaledTS = 0;
index = 1;
%factor = exp(-scaleFactorTime/timeconst);
factor = 1;
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
        index = index + 1;
        regularTS = regularTS + scaleFactorTime;
        events.activityOn(index) = valOn;
        events.activityOff(index) = valOff;
        events.ts(index) = regularTS;
    end
    
    if scaledTS ~= regularTS
        index = index + 1;
    end
    if recording.p(event) == 1
        events.activityOn(index) = recording.activityOn(event);
        if index > 1
            events.activityOff(index) = events.activityOff(index-1) * factor;
        end
    else
        events.activityOn(index) = valOn;
        events.activityOff(index) = recording.activityOff(event);
    end
end