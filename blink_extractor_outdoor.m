if ~exist('recordingsOutdoor', 'var')
    disp('loading compressed recordings from file...')
    load('recordingsOutdoor.mat')
end
names = fieldnames(recordingsOutdoor);
outdoor = Collection('outdoor');
for s = 1:numel(names)
    name = names{s};
    addprop(outdoor, name);
    subject = Subject(name, outdoor);
    if strcmp(name, 'laure')
        subject.addrecording(1, recordingsOutdoor.(name)(1), true);
        rec = subject.Recordings{1};
        rec.Center.Location = [139 152];
        rec.Left.Location =   [ 11 146];
        rec.Right.Location =  [246 152];
        rec.Center.Times = [646900     7633960];
        rec.Left.Times = 17334640;
        rec.Right.Times = [27585390    29687210];
        subject.addrecording(2, recordingsOutdoor.(name)(2), false);
        subject.addrecording(3, recordingsOutdoor.(name)(3), false);
    elseif strcmp(name, 'kevin')
        subject.addrecording(2, recordingsOutdoor.(name)(2), true);
        rec = subject.Recordings{2};
        rec.Center.Location = [136 137];
        rec.Left.Location =   [ 89 132];
        rec.Right.Location =  [186 134];
        rec.Center.Times = [10453000, 18710460];
        %rec.Left.Times = [15470000, 17780000];
        rec.Right.Times = [41431800  46166080];
        subject.CorrelationThreshold = 0.90;
        subject.addrecording(1, recordingsOutdoor.(name)(1), false);
        subject.addrecording(3, recordingsOutdoor.(name)(3), false);
    elseif strcmp(name, 'francesco')
        subject.addrecording(1, recordingsOutdoor.(name)(1), true);
        rec = subject.Recordings{1};
        rec.Center.Location = [136 137];
        rec.Left.Location = [47 135];
        rec.Right.Location = [258 138];
        rec.Center.Times = [8202000, 1580000];
        rec.Left.Times = 21615000;
        rec.Right.Times = [41767600, 46037840, 47094080];
        subject.CorrelationThreshold = 0.9;
        subject.addrecording(2, recordingsOutdoor.(name)(2), false);
        subject.addrecording(3, recordingsOutdoor.(name)(3), false);
    elseif strcmp(name, 'gregor')
        subject.addrecording(1, recordingsOutdoor.(name)(1), false);
        rec.Center.Location = [157 156];
        rec.Center.Times = 7640000; %, 8570000
        %rec.Right.Location = [223 148];
        rec.Left.Location = [81 158];
        rec.Left.Times = [13640000,14888000 ];
    elseif strcmp(name, 'ricardo')
        subject.addrecording(1, recordingsOutdoor.(name)(1), false);
        rec = subject.Recordings{1};
        rec.Center.Location = [136 137];
        rec.Left.Location = [47 135];
        rec.Right.Location = [258 138];
        rec.Center.Times = [8202000, 1580000];
        rec.Left.Times = 21615000;
        rec.Right.Times = [21615000];  
        subject.addrecording(2, recordingsOutdoor.(name)(2), false);
        subject.addrecording(3, recordingsOutdoor.(name)(3), false);
    else
        for r = 1:length(recordingsOutdoor.(name))
            subject.addrecording(r, recordingsOutdoor.(name)(r), false);
        end
    end
    outdoor.(name) = subject;
    
    r = outdoor.(name).gettrainingrecordingindex;
    if r ~= 0
        outdoor.(name).Modelblink = outdoor.(name).Recordings{r}.getmodelblink(30);
    end
end

clear('names', 'rec', 'name', 'subject', 'r', 's')