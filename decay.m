function events = decay(recording, resolution)
%DECAY Summary of this function goes here
%   Detailed explanation goes here

timeconst = 50000;
arrayLength = round((recording.ts(end)-recording.ts(1))/resolution);
%if mod(recording.ts(end), resolution) ~= 0
%    arrayLength = arrayLength + 1;
%end

events.ts = zeros(1, arrayLength);
events.activityOn = zeros(1, arrayLength);
events.activityOff = zeros(1, arrayLength);

%recording doesn't always start at 1
for index = 1:arrayLength
    timestamp = recording.ts(1)/resolution + resolution * (index -1);
    events.ts(index) = timestamp;
    
    temp = recording.ts - timestamp;
    diff = max(temp(temp<=0)); %difference to the previous timestamp

    if diff == 0 %accounts also for multiple events at one timestamp
        tic
        if ismember(0, recording.p(recording.ts == timestamp)) % there are OFF events for this timestamp
            events.activityOn(index) = max(recording.activityOn((recording.ts == timestamp)));
        end
        toc
        if ismember(1, recording.p(recording.ts == timestamp)) % there are ON events for this timestamp
            events.activityOff(index) = max(recording.activityOff((recording.ts == timestamp)));
        end            
    %else
    %    if recording.p(recording.ts == (events.ts(index) + diff)) == 1
    %        events.activityOn(index) = recording.activityOn(recording.ts == (events.ts(index) + diff)) * exp(diff / timeconst)
    %    else
    %        events.activityOff(index) = recording.activityOff(recording.ts == (events.ts(index) + diff)) * exp(diff / timeconst)
    %    end
    end
end