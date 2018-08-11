figure
hold on
names = {'fede', 'alex', 'laure'};

for s = 1:numel(names)
    if s == 1
        disp('Fede/run1.es')
        fede = Subject(names{s});
        fede.addrecording(1, Recording(eventsFede, true));
        fede.Recordings{1}.Center.Location = [142 123];
        fede.Recordings{1}.Left.Location = [ 52 117];
        fede.Recordings{1}.Right.Location =  [218 124];
        fede.Recordings{1}.Center.Times = [2442000, 5139000, 6777000, 9031000, 10920000];
        fede.Recordings{1}.Left.Times = [16210000, 17050000, 19360000, 20350000];
        fede.Recordings{1}.Right.Times = [31290000, 36140000];
        fede.Recordings{1}.AmplitudeScale = 64;
        subjects(s) = fede;
    elseif s == 2
        disp('Alex/run1.es')
        alex = Subject(names{s});
        alex.addrecording(1, Recording(eventsAlex, true));
        %alex.Recordings{1}.blinkCoordinates = [142 159; 102 138; 213 138];
        alex.Recordings{1}.Center.Location = [142 159];
        alex.Recordings{1}.Left.Location =   [ 72 136];
        alex.Recordings{1}.Right.Location =  [213 138];
        alex.Recordings{1}.Center.Times = [1012000, 2010000, 6195000];
        alex.Recordings{1}.Left.Times = [13560000, 14770000];
        alex.Recordings{1}.Right.Times = [30240000, 32740000, 34730000];
        alex.Recordings{1}.AmplitudeScale = 54;
        subjects(s) = alex;
    elseif s == 3
        disp('Laure/run3.es')
        laure = Subject(names{s});
        laure.addrecording(3, Recording(eventsLaure, true));
        laure.Recordings{3}.Center.Location = [143 113]; 
        laure.Recordings{3}.Left.Location =   [ 92 106];
        laure.Recordings{3}.Right.Location =  [193 111];
        laure.Recordings{3}.Center.Times = [2940000, 6922000];
        laure.Recordings{3}.Left.Times = [15470000, 17780000];
        laure.Recordings{3}.Right.Times = [28000000, 29200000];
        laure.Recordings{3}.AmplitudeScale = 73;
        subjects(s) = laure;
    end
    
    for r = 1:numel(subjects(s).Recordings)
        if ~isempty(subjects(s).Recordings{r}) && subjects(s).Recordings{r}.IsTrainingRecording
            break
        end
    end
        
    [averageOn, averageOff, varianceOn, varianceOff] = subjects(s).Recordings{r}.getmodelblink(300000);
    ax = subplot(1,numel(names),s);
    hold on
    
    x = 1:length(varianceOn);
    filterResolution = length(averageOn) / 100;
    movingAverageWindow = ones(1, filterResolution)/filterResolution;

    filteredAverageOn = filter(movingAverageWindow, 1, averageOn);
    filteredSigmaOn = filter(movingAverageWindow, 1, sqrt(varianceOn));
    filteredAverageOff = filter(movingAverageWindow, 1, averageOff);
    filteredSigmaOff = filter(movingAverageWindow, 1, sqrt(varianceOff));
    title(ax, names{s})
    shadedErrorBar(x, filteredAverageOn, filteredSigmaOn, 'lineprops', '-b')
    shadedErrorBar(x, filteredAverageOff, filteredSigmaOff, 'lineprops', '-r')

end