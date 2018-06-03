recording = fullfile('~', 'Recordings', 'face-detection', 'Fede', 'run1.es');

if exist('events', 'var') == 0
    tic
    events = load_eventstream(recording);
    toc
end

eye = crop_spatial(events, 142, 123, 19, 15);
blinks = [2432000, 5129000, 6767000, 9021000, 10910000];
colors = ["blue", "red",  "cyan", "magenta", "black"];
blinkstart = 2002100;
blinklength = 400000;
eye = activity(eye, 50000, true);

%representation = "events";
representation = "continuous";

if representation == "events"
    for i = 1:length(blinks)
        indexes = eye.ts >= blinks(i) & eye.ts <= (blinks(i)+blinklength);
        on = stem(eye.ts(indexes)-blinks(i), eye.activityOn(indexes));
        on.Color = colors(1);
        hold on
        off = stem(eye.ts(indexes)-blinks(i), eye.activityOff(indexes));
        off.Color = colors(2);
    end
else
    scaleFactor = 10;
    eye = shannonise(eye, scaleFactor);
    blinks = blinks / scaleFactor;
    blinklength = blinklength / scaleFactor;
    masterOn = zeros(1,blinklength/ scaleFactor);
    masterOff = masterOn;
    
    for i = 1:length(blinks)
        indexes = eye.ts >= blinks(i) & eye.ts <= (blinks(i)+blinklength);
        %on = plot(eye.ts(indexes)-blinks(i), eye.activityOn(indexes));
        on = plot(eye.activityOn(indexes));
        on.Color = colors(3);
        hold on
        %off = plot(eye.ts(indexes)-blinks(i), eye.activityOff(indexes));
        off = plot(eye.activityOff(indexes));
        off.Color = colors(3);
        masterOn = masterOn + eye.activityOn(indexes);
        masterOff = masterOff + eye.activityOff(indexes);
    end
    masterOn = masterOn / length(blinks);
    masterOff = masterOff / length(blinks);
    hold on
    averageOn = plot(masterOn);
    averageOn.Color = colors(1);
    averageOn.LineWidth = 2;
    averageOff = plot(masterOff);
    averageOff.Color = colors(1);
    averageOff.LineWidth = 2;
    
end

