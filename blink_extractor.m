path = fullfile('~', 'Recordings', 'face-detection');

subject = 'Fede/run1.es'
coordinates = [142 123];
blinks = [2432000, 5129000, 6767000, 9021000, 10910000];
amplitudeScale = 60;

%subject = 'Alex/run1.es'
%coordinates = [142 159];
%blinks = [1012000, 2010000, 6195000];
%amplitudeScale = 74;

%subject = 'Laur/run3.es'
%coordinates = [143 113];
%blinks = [2930000, 6912000];
%amplitudeScale = 67;

path = fullfile(path, subject);
if ~exist('events', 'var') || ~exist('loadedSubject', 'var') || ~strcmp(loadedSubject, subject)
    tic
    events = load_eventstream(path);
    toc
    loadedSubject = subject;
end

eye = crop_spatial(events, coordinates(1), coordinates(2), 19, 15);
colors = ["blue", "red",  "cyan", "magenta", "black"];
blinklength = 400000;
eye = activity(eye, 50000, true);

representation = "events";
%representation = "continuous";

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
        indexes = eye.ts >= blinks(i) & eye.ts < (blinks(i)+blinklength);
        %on = plot(eye.ts(indexes)-blinks(i), eye.activityOn(indexes));
        on = plot(eye.activityOn(indexes)/amplitudeScale);
        on.Color = colors(3);
        hold on
        %off = plot(eye.ts(indexes)-blinks(i), eye.activityOff(indexes));
        off = plot(eye.activityOff(indexes)/amplitudeScale);
        off.Color = colors(3);
        % normalise over number of blinks and a normalising factor that is specific to each recording
        scaledAverageOn = eye.activityOn(indexes) / length(blinks) / amplitudeScale;
        masterOn = masterOn + scaledAverageOn;
        scaledAverageOff = eye.activityOff(indexes) / length(blinks) / amplitudeScale;
        masterOff = masterOff + scaledAverageOff;
    end
    hold on
    averageOn = plot(masterOn);
    averageOn.Color = colors(1);
    averageOn.LineWidth = 2;
    averageOff = plot(masterOff);
    averageOff.Color = colors(1);
    averageOff.LineWidth = 2;
   
    hold on
    %plot(fedeOn/60);
    %plot(fedeOff/60);
    %plot(alexOn/74);
    %plot(alexOff/74);
    %plot(laurOn/67);
    %plot(laurOff/67);
    
end

