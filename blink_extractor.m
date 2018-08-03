path = fullfile('~', 'Recordings', 'face-detection');

subject = 1
if subject == 1
    subject = 'Fede/run1.es'
    coordinates = [142 123; 52 117; 218 124];
    blinks = [2442000     5139000     6777000     9031000    10920000;
            16210000    17050000    19360000    20350000      0;
            31290000    36140000    0  0 0];
    amplitudeScale = 64;
elseif subject == 2
    subject = 'Alex/run1.es'
    coordinates = [142 159; 102 138; 213 138];
    blinks = [1012000, 2010000, 6195000;
                13560000, 14770000, 0;
                30240000, 32740000, 34730000];
    amplitudeScale = 54;
else
    subject = 'Laur/run3.es'
    coordinates = [143 113; 92 106; 193 111];
    blinks = [2940000, 6922000;
                15470000, 17780000;
                28000000, 29200000];
    amplitudeScale = 73;
end

path = fullfile(path, subject);
if ~exist('events', 'var') || ~exist('loadedSubject', 'var') || ~strcmp(loadedSubject, subject)
    tic
    events = load_eventstream(path);
    toc
    loadedSubject = subject;
end

absMasterOn = zeros(1,4000);
absMasterOff = absMasterOn;
averages = cell(2,3);

for l = 1:3
    eye = crop_spatial(events, coordinates(l, 1), coordinates(l, 2), 19, 15);
    colors = ["blue", "red",  "cyan", "magenta", "black"];
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
        blinkRow = blinks(l,:) / scaleFactor;
        blinklength = blinklength / scaleFactor;
        masterOn = zeros(1,blinklength/ scaleFactor);
        masterOff = masterOn;

        for i = 1:nnz(blinkRow>0)
            indexes = eye.ts >= blinkRow(i) & eye.ts < (blinkRow(i)+blinklength);
            %on = plot(eye.ts(indexes)-blinkRow(i), eye.activityOn(indexes));
            on = plot(eye.activityOn(indexes)/amplitudeScale);
            on.Color = colors(3);
            hold on
            %off = plot(eye.ts(indexes)-blinkRow(i), eye.activityOff(indexes));
            off = plot(eye.activityOff(indexes)/amplitudeScale);
            off.Color = colors(3);
            % normalise over number of blinkRow and a normalising factor that is specific to each recording
            scaledAverageOn = eye.activityOn(indexes) / nnz(blinkRow>0) / amplitudeScale;
            masterOn = masterOn + scaledAverageOn;
            scaledAverageOff = eye.activityOff(indexes) / nnz(blinkRow>0) / amplitudeScale;
            masterOff = masterOff + scaledAverageOff;
        end
        hold on
        averageOn = plot(masterOn);
        averageOn.Color = colors(1);
        averageOn.LineWidth = 2;
        %store all the averages for each location
        averages{1, l} = masterOn;
        averageOff = plot(masterOff);
        averageOff.Color = colors(1);
        averageOff.LineWidth = 2;
        averages{2, l} = masterOff;

        %hold on
        %plot(fedeOn/60);
        %plot(fedeOff/60);
        %plot(alexOn/74);
        %plot(alexOff/74);
        %plot(laurOn/67);
        %plot(laurOff/67);
        absMasterOn = (absMasterOn + masterOn/3);
        absMasterOff = (absMasterOff + masterOff/3);
    end
end
hold on
absOn = plot(absMasterOn); 
absOn.Color = colors(4);
absOn.LineWidth = 3;
absOff = plot(absMasterOff);
absOff.Color = colors(4);
absOff.LineWidth = 3;
