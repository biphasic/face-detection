figure
hold on
numberOfSubjects = 3;
filters = cell(2,numberOfSubjects);
for s = 1:numberOfSubjects
    if s == 1
        subject = 'Fede/run1.es'
        events = eventsFede;
        coordinates = [142 123; 52 117; 218 124];
        blinks = [2442000     5139000     6777000     9031000    10920000;
                16210000    17050000    19360000    20350000      0;
                31290000    36140000    0  0 0];
        amplitudeScale = 64;
    elseif s == 2
        events = eventsAlex;
        subject = 'Alex/run1.es'
        %coordinates = [142 159; 102 138; 213 138];
        coordinates = [142 159; 72 136; 213 138];
        blinks = [1012000, 2010000, 6195000;
                    13560000, 14770000, 0;
                    30240000, 32740000, 34730000];
        amplitudeScale = 54;
    else
        subject = 'Laure/run3.es'
        events = eventsLaure;
        coordinates = [143 113; 92 106; 193 111];
        blinks = [2940000, 6922000;
                    15470000, 17780000;
                    28000000, 29200000];
        amplitudeScale = 73;
    end

    blinkLength = 300000;
    absMasterOn = zeros(1,blinkLength/100);
    absMasterOff = absMasterOn;
    averages = cell(2,3);

    %%% 3 model blink locations %%%
    for l = 1:3
        eye = crop_spatial(events, coordinates(l, 1), coordinates(l, 2), 19, 15);
        colors = ["blue", "red",  "cyan", "magenta", "black"];
        eye = activity(eye, 50000, true);
        blinklength = blinkLength;

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
            masterOn = zeros(1, blinklength/ scaleFactor);
            masterOff = masterOn;

            %%% however many blinks in one location %%%
            ax = subplot(3, 9, (s-1)*3+l);
            if l == 1
                title(ax, 'center');
            elseif l == 2
                title(ax, 'left');
            else
                title(ax, 'right');
            end
            hold on
            for i = 1:nnz(blinkRow>0)
                indexes = eye.ts >= blinkRow(i) & eye.ts < (blinkRow(i)+blinklength);
                %plot events: on = plot(eye.ts(indexes)-blinkRow(i), eye.activityOn(indexes));
                %plot events: off = plot(eye.ts(indexes)-blinkRow(i), eye.activityOff(indexes));
                % normalise over number of blinkRow and a normalising factor that is specific to each recording
                scaledAverageOn = eye.activityOn(indexes) / amplitudeScale;
                on = plot(ax, scaledAverageOn);
                on.Color = colors(3);
                masterOn = masterOn + scaledAverageOn / nnz(blinkRow>0);
                scaledAverageOff = eye.activityOff(indexes) / amplitudeScale;
                off = plot(ax, scaledAverageOff);
                off.Color = colors(3);
                masterOff = masterOff + scaledAverageOff / nnz(blinkRow>0);
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

            absMasterOn = (absMasterOn + masterOn/3);
            absMasterOff = (absMasterOff + masterOff/3);
        end
    end
    
    %%% variance across blinks of recent subject %%%
    averageOn = absMasterOn;
    averageOff = absMasterOff;
    varianceOn = zeros(1, length(averages{1}));
    varianceOff = varianceOn;
    len = length(averages(1,:));
    for i = 1:len
        varianceOn = varianceOn + (averages{1, i} - averageOn).^2 / len;
        varianceOff = varianceOff + (averages{2, i} - averageOff).^2 / len;
    end

    x = 1:length(varianceOn);
    filterResolution = length(averageOn) / 100;
    movingAverageWindow = ones(1, filterResolution)/filterResolution;

    filteredAverageOn = filter(movingAverageWindow, 1, averageOn);
    filteredSigmaOn = filter(movingAverageWindow, 1, sqrt(varianceOn));
    filteredAverageOff = filter(movingAverageWindow, 1, averageOff);
    filteredSigmaOff = filter(movingAverageWindow, 1, sqrt(varianceOff));
    filters{1, s} = filteredAverageOn;
    filters{2, s} = filteredAverageOff;
    hold on
    %shadedErrorBar(x, averageOn, sqrt(varianceOn), 'lineprops', '-r')
    %shadedErrorBar(x, averageOff, sqrt(varianceOff), 'lineprops', '-r')
    ax = subplot(3,3*numberOfSubjects,[7+3*s 7+3*s+1 7+3*s+2]);
    title(ax, subject)
    shadedErrorBar(x, filteredAverageOn, filteredSigmaOn, 'lineprops', '-b')
    shadedErrorBar(x, filteredAverageOff, filteredSigmaOff, 'lineprops', '-r')
    
end