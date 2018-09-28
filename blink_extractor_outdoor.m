figure
hold on
names = {'laure', 'kevin'};

for s = 1:numel(names)
    if s == 1
        disp('Laure/2-filtered.es')
        laure = Subject(names{s});
        laure.addrecording(2, Recording(outdoorEventsLaure(2), true));
        laure.Recordings{2}.Center.Location = [136 155]; %mitte des Auges 
        laure.Recordings{2}.Left.Location =   [ 47 147];
        laure.Recordings{2}.Right.Location =  [229 154];
        laure.Recordings{2}.Center.Times = [4136000, 5482000];
        %laure.Recordings{2}.Left.Times = [14250000]; not a good shape
        %laure.Recordings{2}.Right.Times = [28000000, 29200000];
        laure.AmplitudeScale = 20;
        laure.CorrelationThreshold = 0.9;
        laure.addrecording(1, Recording(eventsLaure(1), false));
        laure.addrecording(3, Recording(eventsLaure(3), false));
        outdoorSubjects(s) = laure;
    elseif s == 2
        disp('Kevin')
        kevin = Subject(names{s});
        kevin.addrecording(2, Recording(outdoorEventsKevin(2), true));
        kevin.Recordings{2}.Center.Location = [136 137]; %mitte des Auges
        kevin.Recordings{2}.Left.Location =   [ 89 132];
        kevin.Recordings{2}.Right.Location =  [186 134];
        kevin.Recordings{2}.Center.Times = [10440000, 18700000];
        %kevin.Recordings{2}.Left.Times = [15470000, 17780000];
        %kevin.Recordings{2}.Right.Times = [28000000, 29200000];
        kevin.AmplitudeScale = 13;
        kevin.CorrelationThreshold = 0.9;
        kevin.addrecording(1, Recording(eventsLaure(1), false));
        kevin.addrecording(3, Recording(eventsLaure(3), false));
        outdoorSubjects(s) = kevin;
    elseif s == 3
        disp('Gregor/test7-cour')
        gregor = Subject(names{s});
        gregor.addrecording(1, Recording(eventsGregor, true));
        gregor.Recordings{1}.Center.Location = [157 156];
        gregor.Recordings{1}.Right.Location = [223 148];
        gregor.Recordings{1}.Left.Location = [81 158];
        gregor.Recordings{1}.Center.Times = [7640000]; %, 8570000
        gregor.Recordings{1}.Left.Times = [13640000,14888000 ]; %
        gregor.AmplitudeScale = 25;
        outdoorsubjects(s) = gregor;
    else
    end
    
    %check for first recording that is training recording to calculate ModelBlink from
    for r = 1:numel(outdoorSubjects(s).Recordings)
        if ~isempty(outdoorSubjects(s).Recordings{r}) && outdoorSubjects(s).Recordings{r}.IsTrainingRecording
            break
        end
    end
    
    %retrieve smoothed Model and its variance
    m = outdoorSubjects(s).Modelblink;
    [m.AverageOn, m.AverageOff, m.VarianceOn, m.VarianceOff] = outdoorSubjects(s).Recordings{r}.getmodelblink(outdoorSubjects(s).AmplitudeScale, outdoorSubjects(s).BlinkLength, 30);
    outdoorSubjects(s).Modelblink = m;
    ax = subplot(1,numel(names),s);
    %ax = subplot(1,1,1);
    hold on
    
    if 1 == 1
        [blinksOn, blinksOff] = outdoorSubjects(s).Recordings{r}.getblinks(outdoorSubjects(s).AmplitudeScale, outdoorSubjects(s).BlinkLength);
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