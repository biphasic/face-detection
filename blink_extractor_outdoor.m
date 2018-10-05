figure
hold on
names = {'laure', 'kevin', 'francesco'};

for s = 1:numel(names)
    if s == 1
        disp('Laure/1-filtered.es')
        laure = Subject(names{s});
        laure.addrecording(1, outdoorEventsLaure(1), true);
        laure.Recordings{1}.Center.Location = [139 152];
        laure.Recordings{1}.Left.Location =   [ 11 146];
        laure.Recordings{1}.Right.Location =  [246 152];
        laure.Recordings{1}.Center.Times = [646900, 7635260];
        laure.Recordings{1}.Left.Times = [17337700];
        laure.Recordings{1}.Right.Times = [27588050, 29688650];
        laure.AmplitudeScale = 20;
        laure.CorrelationThreshold = 0.88;
        laure.addrecording(2, outdoorEventsLaure(2), false);
        laure.addrecording(3, outdoorEventsLaure(3), false);
        outdoorSubjects.(names{s}) = laure;
    elseif s == 2
        disp('Kevin/2.es')
        kevin = Subject(names{s});
        kevin.addrecording(2, outdoorEventsKevin(2), true);
        kevin.Recordings{2}.Center.Location = [136 137];
        kevin.Recordings{2}.Left.Location =   [ 89 132];
        kevin.Recordings{2}.Right.Location =  [186 134];
        kevin.Recordings{2}.Center.Times = [10440000, 18697460];
        %kevin.Recordings{2}.Left.Times = [15470000, 17780000];
        kevin.Recordings{2}.Right.Times = [41417300, 46152760];
        kevin.AmplitudeScale = 19;
        kevin.CorrelationThreshold = 0.90;
        kevin.addrecording(1, outdoorEventsKevin(1), false);
        kevin.addrecording(3, outdoorEventsKevin(3), false);
        outdoorSubjects.(names{s}) = kevin;
    elseif s == 3
        disp('Francesco/1-filtered')
        francesco = Subject(names{s});
        francesco.addrecording(1, outdoorEventsFrancesco(1), true);
        francesco.Recordings{1}.Center.Location = [136 137];
        francesco.Recordings{1}.Left.Location = [47 135];
        francesco.Recordings{1}.Right.Location = [258 138];
        francesco.Recordings{1}.Center.Times = [8202000, 1580000];
        francesco.Recordings{1}.Left.Times = [21615000];
        francesco.Recordings{1}.Right.Times = [41767600, 46037840, 47094080];
        francesco.AmplitudeScale = 11;
        francesco.CorrelationThreshold = 0.9;
        francesco.addrecording(2, outdoorEventsFrancesco(2), false);
        francesco.addrecording(3, outdoorEventsFrancesco(3), false);
        outdoorSubjects.(names{s}) = francesco;
    elseif s == 4
        disp('Gregor/test7-cour')
        gregor = Subject(names{s});
        gregor.addrecording(1, eventsGregor, true);
        gregor.Recordings{1}.Center.Location = [157 156];
        gregor.Recordings{1}.Right.Location = [223 148];
        gregor.Recordings{1}.Left.Location = [81 158];
        gregor.Recordings{1}.Center.Times = [7640000]; %, 8570000
        gregor.Recordings{1}.Left.Times = [13640000,14888000 ]; %
        gregor.AmplitudeScale = 25;
        outdoorsubjects.(s) = gregor;
    else
    end
    
    r = outdoorSubjects.(names{s}).gettrainingrecordingindex;
    
    %retrieve smoothed Model and its variance
    m = outdoorSubjects.(names{s}).Modelblink;
    [m.AverageOn, m.AverageOff, m.VarianceOn, m.VarianceOff] = outdoorSubjects.(names{s}).Recordings{r}.getmodelblink(30);
    outdoorSubjects.(names{s}).Modelblink = m;
    ax = subplot(1,numel(names),s);
    %ax = subplot(1,1,1);
    hold on
    
    if 1 == 2
        [blinksOn, blinksOff] = outdoorSubjects.(names{s}).Recordings{r}.getallblinks();
        fields = fieldnames(blinksOn);
        for j = 3:length(fields)
            for i = 1:size(blinksOn.(fields{j}),1)
                a = plot(blinksOn.(fields{j})(i,:));
                [xcOn, lagOn] = xcorr(blinksOn.(fields{j})(1,:), blinksOn.(fields{j})(i,:));
                [~, indexOn] = max(abs(xcOn));
                lagDiffOn = lagOn(indexOn);
                [xcOff, lagOff] = xcorr(blinksOff.(fields{j})(1,:), blinksOff.(fields{j})(i,:));
                [~, indexOff] = max(abs(xcOff));
                lagDiffOff = lagOff(indexOff);
                lagDiff = 0.6*lagDiffOn + 0.4*lagDiffOff;
                if abs(lagDiff) > 1 %resembles accuracy of lagdiff * 100us
                    timestamp = outdoorSubjects.(names{s}).Recordings{r}.(fields{j}).Times(i)-lagDiff*100;
                    disp(['suggested timestamp for blink ', int2str(i), ' at ', fields{j}, ' is: ', int2str(timestamp)])
                end
                a.Color = 'blue';
                b = plot(blinksOff.(fields{j})(i,:));
                b.Color = 'red';
            end
            [averageOnFirst, averageOffFirst] = outdoorSubjects.(names{s}).Recordings{r}.(fields{1}).getaverages();
            [averageOn, averageOff] = outdoorSubjects.(names{s}).Recordings{r}.(fields{j}).getaverages();
            [xcOn, lagOn] = xcorr(averageOnFirst, averageOn);
            [~, indexOn] = max(abs(xcOn));
            lagDiffOn = lagOn(indexOn);
            [xcOff, lagOff] = xcorr(averageOffFirst, averageOff);
            [~, indexOff] = max(abs(xcOff));
            lagDiffOff = lagOff(indexOff);
            lagDiff = (lagDiffOn + lagDiffOff)/2;
            if abs(lagDiff) > 1
                disp(['lag between ', fields{1}, ' and ', fields{j}, ' is ', int2str(lagDiff*100), ' us'])
            end
        end
    end
    
    %plot both average and variance for ON and OFF
    title(ax, names{s})
    ax = shadedErrorBar(1:length(m.AverageOn), m.AverageOn, m.VarianceOn, 'lineprops', '-b');
    ax.mainLine.LineWidth = 3;
    ax = shadedErrorBar(1:length(m.AverageOff), m.AverageOff, m.VarianceOff, 'lineprops', '-r');
    ax.mainLine.LineWidth = 3;
    ylim([0 inf])
    
    clear(names{s}, 'r', 'm', 'ax', 's')
end