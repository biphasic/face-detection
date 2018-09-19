figure
hold on
names = {'fede', 'alex', 'laure', 'gregor'};

for s = 1:numel(names)
    if s == 1
        disp('Fede/run1.es')
        fede = Subject(names{s});
        fede.addrecording(1, Recording(eventsFede(1), true));
        fede.Recordings{1}.Center.Location = [142 123];
        fede.Recordings{1}.Left.Location = [ 52 117];
        fede.Recordings{1}.Right.Location =  [218 124];
        fede.Recordings{1}.Center.Times = [2442000, 5139000, 6777000, 9031000, 10920000];
        fede.Recordings{1}.Left.Times = [16210000, 17050000, 19360000, 20350000];
        fede.Recordings{1}.Right.Times = [31290000, 36140000];
        fede.AmplitudeScale = 64;
        fede.CorrelationThreshold = 0.88;
        fede.addrecording(2, Recording(eventsFede(2), false));
        fede.addrecording(3, Recording(eventsFede(3), false));
        subjects(s) = fede;
    elseif s == 2
        disp('Alex/run1.es')
        alex = Subject(names{s});
        alex.addrecording(1, Recording(eventsAlex(1), true));
        %alex.Recordings{1}.blinkCoordinates = [142 159; 102 138; 213 138];
        alex.Recordings{1}.Center.Location = [142 159];
        alex.Recordings{1}.Left.Location =   [ 72 136];
        alex.Recordings{1}.Right.Location =  [213 138];
        alex.Recordings{1}.Center.Times = [1012000, 2010000, 6195000];
        alex.Recordings{1}.Left.Times = [13560000, 14770000];
        alex.Recordings{1}.Right.Times = [30240000, 32740000, 34730000];
        alex.AmplitudeScale = 54;
        alex.CorrelationThreshold = 0.88;
        alex.addrecording(2, Recording(eventsAlex(2), false));
        alex.addrecording(3, Recording(eventsAlex(3), false));
        subjects(s) = alex;
    elseif s == 3
        disp('Laure/run3.es')
        laure = Subject(names{s});
        laure.addrecording(3, Recording(eventsLaure(3), true));
        laure.Recordings{3}.Center.Location = [143 113]; 
        laure.Recordings{3}.Left.Location =   [ 92 106];
        laure.Recordings{3}.Right.Location =  [193 111];
        laure.Recordings{3}.Center.Times = [2940000, 6922000];
        laure.Recordings{3}.Left.Times = [15470000, 17780000];
        laure.Recordings{3}.Right.Times = [28000000, 29200000];
        laure.AmplitudeScale = 73;
        laure.CorrelationThreshold = 0.9;
        laure.addrecording(1, Recording(eventsLaure(1), false));
        laure.addrecording(2, Recording(eventsLaure(2), false));
        subjects(s) = laure;
    elseif s == 4
        disp('Gregor/test7-cour')
        gregor = Subject(names{s});
        gregor.addrecording(1, Recording(eventsGregor, true));
        gregor.Recordings{1}.Center.Location = [147 148];
        gregor.Recordings{1}.Right.Location = [213 140];
        gregor.Recordings{1}.Left.Location = [71 150];
        gregor.Recordings{1}.Center.Times = [7640000]; %, 8570000
        gregor.Recordings{1}.Left.Times = [13640000,14888000 ]; %
        gregor.AmplitudeScale = 25;
        subjects(s) = gregor;
    end
    
    %check for first recording that is training recording to calculate ModelBlink from
    for r = 1:numel(subjects(s).Recordings)
        if ~isempty(subjects(s).Recordings{r}) && subjects(s).Recordings{r}.IsTrainingRecording
            break
        end
    end
    
    %retrieve smoothed Model and its variance
    m = subjects(s).Modelblink;
    [m.AverageOn, m.AverageOff, m.VarianceOn, m.VarianceOff] = subjects(s).Recordings{r}.getmodelblink(subjects(s).AmplitudeScale, subjects(s).BlinkLength, 30);
    subjects(s).Modelblink = m;
    ax = subplot(1,numel(names),s);
    %ax = subplot(1,1,1);
    hold on
    
    if 1 == 2
        [blinksOn, blinksOff] = subjects(s).Recordings{r}.getblinks(subjects(s).AmplitudeScale, subjects(s).BlinkLength);
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