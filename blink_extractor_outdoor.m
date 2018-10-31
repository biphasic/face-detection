if ~exist('outdoorEventsLaure', 'var')
    load('recordingsOutdoor.mat')
end
names = {'laure', 'kevin', 'francesco'};
outdoor = Collection('outdoor');
for s = 1:numel(names)
    if s == 1
        disp('Laure/1-filtered.es')
        laure = Subject(names{s}, outdoor);
        laure.addrecording(1, outdoorEventsLaure(1), true);
        laure.Recordings{1}.Center.Location = [139 152];
        laure.Recordings{1}.Left.Location =   [ 11 146];
        laure.Recordings{1}.Right.Location =  [246 152];
        laure.Recordings{1}.Center.Times = [646900     7633960];
        laure.Recordings{1}.Left.Times = 17334640;
        laure.Recordings{1}.Right.Times = [27585390    29687210];
        laure.CorrelationThreshold = 0.88;
        laure.addrecording(2, outdoorEventsLaure(2), false);
        laure.addrecording(3, outdoorEventsLaure(3), false);
        addprop(outdoor, laure.Name);
        outdoor.(names{s}) = laure;
    elseif s == 2
        disp('Kevin/2.es')
        kevin = Subject(names{s}, outdoor);
        kevin.addrecording(2, outdoorEventsKevin(2), true);
        kevin.Recordings{2}.Center.Location = [136 137];
        kevin.Recordings{2}.Left.Location =   [ 89 132];
        kevin.Recordings{2}.Right.Location =  [186 134];
        kevin.Recordings{2}.Center.Times = [10453000, 18710460];
        %kevin.Recordings{2}.Left.Times = [15470000, 17780000];
        kevin.Recordings{2}.Right.Times = [41431800  46166080];
        kevin.CorrelationThreshold = 0.90;
        kevin.addrecording(1, outdoorEventsKevin(1), false);
        kevin.addrecording(3, outdoorEventsKevin(3), false);
        addprop(outdoor, kevin.Name);
        outdoor.(names{s}) = kevin;
    elseif s == 3
        disp('Francesco/1-filtered')
        francesco = Subject(names{s}, outdoor);
        francesco.addrecording(1, outdoorEventsFrancesco(1), true);
        francesco.Recordings{1}.Center.Location = [136 137];
        francesco.Recordings{1}.Left.Location = [47 135];
        francesco.Recordings{1}.Right.Location = [258 138];
        francesco.Recordings{1}.Center.Times = [8202000, 1580000];
        francesco.Recordings{1}.Left.Times = 21615000;
        francesco.Recordings{1}.Right.Times = [41767600, 46037840, 47094080];
        francesco.CorrelationThreshold = 0.9;
        francesco.addrecording(2, outdoorEventsFrancesco(2), false);
        francesco.addrecording(3, outdoorEventsFrancesco(3), false);
        addprop(outdoor, francesco.Name);
        outdoor.(names{s}) = francesco;
    elseif s == 4
        disp('Gregor/test7-cour')
        gregor = Subject(names{s});
        gregor.addrecording(1, eventsGregor, true);
        gregor.Recordings{1}.Center.Location = [157 156];
        gregor.Recordings{1}.Right.Location = [223 148];
        gregor.Recordings{1}.Left.Location = [81 158];
        gregor.Recordings{1}.Center.Times = 7640000; %, 8570000
        gregor.Recordings{1}.Left.Times = [13640000,14888000 ];
        gregor.AmplitudeScale = 25;
        outdoorsubjects.(s) = gregor;
    else
    end
    
    r = outdoor.(names{s}).gettrainingrecordingindex;
    
    outdoor.(names{s}).Modelblink = outdoor.(names{s}).Recordings{r}.getmodelblink(30);
    
    clear(names{s}, 'r', 'm', 'ax', 's')
end