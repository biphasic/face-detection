names = {'fede', 'alex', 'laure'};
indoorSubjects = Collection();
for s = 1:numel(names)
    if s == 1
        disp('Fede/run1.es')
        fede = Subject(names{s});
        fede.addrecording(1, indoorEventsFede(1), true);
        fede.Recordings{1}.Center.Location = [152 131];
        fede.Recordings{1}.Left.Location = [ 62 125];
        fede.Recordings{1}.Right.Location =  [228 132];
        fede.Recordings{1}.Center.Times = [2442000, 5139000, 6777000, 9031000, 10920000];
        fede.Recordings{1}.Left.Times = [16210000, 17050000, 19360000, 20350000];
        fede.Recordings{1}.Right.Times = [31290000, 36140000];
        fede.AmplitudeScale = 64;
        fede.CorrelationThreshold = 0.88;
        fede.addrecording(2, indoorEventsFede(2), false);
        fede.addrecording(3, indoorEventsFede(3), false);
        addprop(indoorSubjects, fede.Name);
        indoorSubjects.(names{s}) = fede;
    elseif s == 2
        disp('Alex/run1.es')
        alex = Subject(names{s});
        alex.addrecording(1, indoorEventsAlex(1), true);
        alex.Recordings{1}.Center.Location = [152 167];
        alex.Recordings{1}.Left.Location =   [ 82 144];
        alex.Recordings{1}.Right.Location =  [223 146];
        alex.Recordings{1}.Center.Times = [1012000, 2010000, 6195000];
        alex.Recordings{1}.Left.Times = [13560000, 14770000];
        alex.Recordings{1}.Right.Times = [30240000, 32740000, 34730000];
        alex.AmplitudeScale = 54;
        alex.CorrelationThreshold = 0.88;
        alex.addrecording(2, indoorEventsAlex(2), false);
        alex.addrecording(3, indoorEventsAlex(3), false);
        addprop(indoorSubjects, alex.Name);
        indoorSubjects.(names{s}) = alex;
    elseif s == 3
        disp('Laure/run3.es')
        laure = Subject(names{s});
        laure.addrecording(3, indoorEventsLaure(3), true);
        laure.Recordings{3}.Center.Location = [153 121]; %Mitte des Auges
        laure.Recordings{3}.Left.Location =   [102 114];
        laure.Recordings{3}.Right.Location =  [203 119];
        laure.Recordings{3}.Center.Times = [2940000, 6922000];
        laure.Recordings{3}.Left.Times = [15470000, 17780000];
        laure.Recordings{3}.Right.Times = [28000000, 29200000];
        laure.AmplitudeScale = 73;
        laure.CorrelationThreshold = 0.9;
        laure.addrecording(1, indoorEventsLaure(1), false);
        laure.addrecording(2, indoorEventsLaure(2), false);
        addprop(indoorSubjects, laure.Name);
        indoorSubjects.(names{s}) = laure;
    end
    
    r = indoorSubjects.(names{s}).gettrainingrecordingindex;
    
    indoorSubjects.(names{s}).Modelblink = indoorSubjects.(names{s}).Recordings{r}.getmodelblink(30);
    
    indoorSubjects.(names{s}).plotmodelblink
    
    clear(names{s}, 'r', 'm', 'ax', 's')
end