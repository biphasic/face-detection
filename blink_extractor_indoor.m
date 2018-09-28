figure
hold on
names = {'fede', 'alex', 'laure'};

for s = 1:numel(names)
    if s == 1
        disp('Fede/run1.es')
        fede = Subject(names{s});
        fede.addrecording(1, Recording(eventsFede(1), true));
        fede.Recordings{1}.Center.Location = [152 131]; %mitte des auges
        fede.Recordings{1}.Left.Location = [ 62 125];
        fede.Recordings{1}.Right.Location =  [228 132];
        fede.Recordings{1}.Center.Times = [2442000, 5139000, 6777000, 9031000, 10920000];
        fede.Recordings{1}.Left.Times = [16210000, 17050000, 19360000, 20350000];
        fede.Recordings{1}.Right.Times = [31290000, 36140000];
        fede.AmplitudeScale = 64;
        fede.CorrelationThreshold = 0.88;
        fede.addrecording(2, Recording(eventsFede(2), false));
        fede.addrecording(3, Recording(eventsFede(3), false));
        indoorSubjects(s) = fede;
    elseif s == 2
        disp('Alex/run1.es')
        alex = Subject(names{s});
        alex.addrecording(1, Recording(eventsAlex(1), true));
        %alex.Recordings{1}.blinkCoordinates = [142 159; 102 138; 213 138];
        alex.Recordings{1}.Center.Location = [152 167]; %Mitte des Auges
        alex.Recordings{1}.Left.Location =   [ 82 144];
        alex.Recordings{1}.Right.Location =  [223 146];
        alex.Recordings{1}.Center.Times = [1012000, 2010000, 6195000];
        alex.Recordings{1}.Left.Times = [13560000, 14770000];
        alex.Recordings{1}.Right.Times = [30240000, 32740000, 34730000];
        alex.AmplitudeScale = 54;
        alex.CorrelationThreshold = 0.88;
        alex.addrecording(2, Recording(eventsAlex(2), false));
        alex.addrecording(3, Recording(eventsAlex(3), false));
        indoorSubjects(s) = alex;
    elseif s == 3
        disp('Laure/run3.es')
        laure = Subject(names{s});
        laure.addrecording(3, Recording(eventsLaure(3), true));
        laure.Recordings{3}.Center.Location = [153 121]; %Mitte des Auges
        laure.Recordings{3}.Left.Location =   [102 114];
        laure.Recordings{3}.Right.Location =  [203 119];
        laure.Recordings{3}.Center.Times = [2940000, 6922000];
        laure.Recordings{3}.Left.Times = [15470000, 17780000];
        laure.Recordings{3}.Right.Times = [28000000, 29200000];
        laure.AmplitudeScale = 73;
        laure.CorrelationThreshold = 0.9;
        laure.addrecording(1, Recording(eventsLaure(1), false));
        laure.addrecording(2, Recording(eventsLaure(2), false));
        indoorSubjects(s) = laure;
    end
    
    %check for first recording that is training recording to calculate ModelBlink from
    for r = 1:numel(indoorSubjects(s).Recordings)
        if ~isempty(indoorSubjects(s).Recordings{r}) && indoorSubjects(s).Recordings{r}.IsTrainingRecording
            break
        end
    end
    
    %retrieve smoothed Model and its variance
    m = indoorSubjects(s).Modelblink;
    [m.AverageOn, m.AverageOff, m.VarianceOn, m.VarianceOff] = indoorSubjects(s).Recordings{r}.getmodelblink(indoorSubjects(s).AmplitudeScale, indoorSubjects(s).BlinkLength, 30);
    indoorSubjects(s).Modelblink = m;
    ax = subplot(1,numel(names),s);
    %ax = subplot(1,1,1);
    hold on
    
    if 1 == 2
        [blinksOn, blinksOff] = indoorSubjects(s).Recordings{r}.getblinks(indoorSubjects(s).AmplitudeScale, indoorSubjects(s).BlinkLength);
        fields = fieldnames(blinksOn);
        for j = 1:length(fields)
            for i = 1:size(blinksOn.(fields{j}),1)
                a = plot(blinksOn.(fields{j})(i,:));
                a.Color = 'blue';
                b = plot(blinksOff.(fields{j})(i,:));
                b.Color = 'red';
            end
        end
    end
    
    %plot both average and variance for ON and OFF
    title(ax, names{s})
    shadedErrorBar(1:length(m.AverageOn), m.AverageOn, m.VarianceOn, 'lineprops', '-b')
    shadedErrorBar(1:length(m.AverageOff), m.AverageOff, m.VarianceOff, 'lineprops', '-r')
    
    clear(names{s}, 'r', 'm', 'ax', 's')
end