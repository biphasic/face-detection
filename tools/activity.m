function events = activity(recording, timeconst, splitOnAndOffActivity)
%ACTIVITY Summary of this function goes here
%   Detailed explanation goes here
if ~exist('splitOnAndOffActivity','var')
    splitOnAndOffActivity = false;
end

events = recording; 

if ~splitOnAndOffActivity
    events.activity = zeros(1, length(recording.ts));
    events.activity(1) = 1;
    for i = 2:length(recording.ts)
        events.activity(i) = events.activity(i-1) * exp(-(events.ts(i) - events.ts(i-1)) / timeconst) + 1;
    end
else % two activities for ON and OFF events respectively
    events.activityOn = zeros(1, length(recording.ts));
    events.activityOff = zeros(1, length(recording.ts));
    [lastOnIndex, lastOffIndex] = deal(1);
    for i = 1:length(recording.ts)
        if events.p(i) == 1
            events.activityOn(i) = events.activityOn(lastOnIndex) * exp(-(events.ts(i) - events.ts(lastOnIndex)) / timeconst) + 1;
            lastOnIndex = i;
        else
            events.activityOff(i) = events.activityOff(lastOffIndex) * exp(-(events.ts(i) - events.ts(lastOffIndex)) / timeconst) + 1;
            lastOffIndex = i;
        end
    end
    events.activityOn(events.activityOn == 0) = NaN;
    events.activityOff(events.activityOff == 0) = NaN;
end