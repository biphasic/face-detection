figure
hold on
names = {'fede', 'alex', 'laure'};
for s = 1:numel(names)
    if s == 1
        disp('Fede/run1.es')
        subjects.(names{s}).recording = eventsFede;
        subjects.(names{s}).blinkCoordinates.center = [142 123];
        subjects.(names{s}).blinkCoordinates.left =   [ 52 117];
        subjects.(names{s}).blinkCoordinates.right =  [218 124];
        subjects.(names{s}).blinkTimes.center = [2442000, 5139000, 6777000, 9031000, 10920000];
        subjects.(names{s}).blinkTimes.left = [16210000, 17050000, 19360000, 20350000];
        subjects.(names{s}).blinkTimes.right = [31290000, 36140000];
        subjects.(names{s}).amplitudeScale = 64;
    elseif s == 2
        disp('Alex/run1.es')
        subjects.(names{s}).recording = eventsAlex;
        %subjects.(names{s}).blinkCoordinates = [142 159; 102 138; 213 138];
        subjects.(names{s}).blinkCoordinates.center = [142 159];
        subjects.(names{s}).blinkCoordinates.left =   [ 72 136];
        subjects.(names{s}).blinkCoordinates.right =  [213 138];
        subjects.(names{s}).blinkTimes.center = [1012000, 2010000, 6195000];
        subjects.(names{s}).blinkTimes.left = [13560000, 14770000];
        subjects.(names{s}).blinkTimes.right = [30240000, 32740000, 34730000];
        subjects.(names{s}).amplitudeScale = 54;
    elseif s == 3
        disp('Laure/run3.es')
        subjects.(names{s}).recording = eventsLaure;
        subjects.(names{s}).blinkCoordinates.center = [143 113]; 
        subjects.(names{s}).blinkCoordinates.left =   [ 92 106];
        subjects.(names{s}).blinkCoordinates.right =  [193 111];
        subjects.(names{s}).blinkTimes.center = [2940000, 6922000];
        subjects.(names{s}).blinkTimes.left = [15470000, 17780000];
        subjects.(names{s}).blinkTimes.right = [28000000, 29200000];
        subjects.(names{s}).amplitudeScale = 73;
    end
    
    blinkLength = 300000;
    absMasterOn = zeros(1,blinkLength/100);
    absMasterOff = absMasterOn;
    averages = cell(2,3);

    %%% 3 model blink locations %%%
    averages = averageBlinkLocations(subjects.(names{s}).blinkCoordinates, subjects.(names{s}).blinkTimes);
    variationOn = calculateVariation
    
    for l = 1:3
        eye = crop_spatial(subjects.(names{s}).recording, subjects.(names{s}).blinkCoordinates(l, 1), subjects.(names{s}).blinkCoordinates(l, 2), 19, 15);
        colors = ["blue", "red",  "cyan", "magenta", "black"];
        eye = activity(eye, 50000, true);
        blinklength = blinkLength;

        %representation = "events";
        representation = "continuous";
        
        if representation == "events"
            for i = 1:length(subjects.(names{s}).blinkTimes)
                indexes = eye.ts >= subjects.(names{s}).blinkTimes(i) & eye.ts <= (subjects.(names{s}).blinkTimes(i)+blinklength);
                on = stem(eye.ts(indexes)-subjects.(names{s}).blinkTimes(i), eye.activityOn(indexes));
                on.Color = colors(1);
                hold on
                off = stem(eye.ts(indexes)-subjects.(names{s}).blinkTimes(i), eye.activityOff(indexes));
                off.Color = colors(2);
            end
        else
            scaleFactor = 10;
            eye = shannonise(eye, scaleFactor);
            blinkRow = subjects.(names{s}).blinkTimes(l,:) / scaleFactor;
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
                scaledAverageOn = eye.activityOn(indexes) / subjects.(names{s}).amplitudeScale;
                on = plot(ax, scaledAverageOn);
                on.Color = colors(3);
                masterOn = masterOn + scaledAverageOn / nnz(blinkRow>0);
                scaledAverageOff = eye.activityOff(indexes) / subjects.(names{s}).amplitudeScale;
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
    subjects.(names{s}).filterOn = filteredAverageOn;
    subjects.(names{s}).filterOff = filteredAverageOff;
    hold on
    %shadedErrorBar(x, averageOn, sqrt(varianceOn), 'lineprops', '-r')
    %shadedErrorBar(x, averageOff, sqrt(varianceOff), 'lineprops', '-r')
    ax = subplot(3,3*numel(names),[7+3*s 7+3*s+1 7+3*s+2]);
    title(ax, names{s})
    shadedErrorBar(x, filteredAverageOn, filteredSigmaOn, 'lineprops', '-b')
    shadedErrorBar(x, filteredAverageOff, filteredSigmaOff, 'lineprops', '-r')
    
end