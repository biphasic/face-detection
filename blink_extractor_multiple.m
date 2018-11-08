if ~exist('multipleEvents', 'var')
    disp('loading compressed recordings from file...')
    load('recordingsMultiple.mat')
end
names = {'felixkevingregor'};
multiple = Collection('multiple');
for s = 1:numel(names)
    name = names{s};
    addprop(multiple, name);
    subject = Subject(name, multiple);
    if s == 1
        n = 3;
        subject.addrecording(n, multipleEvents(n), true);
        %subject.Recordings{n}.Center.Location = [133 140];
        subject.Recordings{n}.Center.Location = [51 131];
        subject.Recordings{n}.Center.Times = [6275000 11230000 15000000];
        subject.Recordings{n}.Left.Location = [25 136];
        subject.Recordings{n}.Left.Times = [11230000    14720540 15000000];
        %subject.Recordings{n}.Left.AmplitudeScaleScale = 0.2;
        subject.Recordings{n}.Right.Location =  [228 136];
        subject.Recordings{n}.Right.Times = [19294785];
        %subject.Recordings{n}.Right.AmplitudeScaleScale = 2;
        subject.CorrelationThreshold = 0.91;
        subject.addrecording(1, multipleEvents(1), false);
        subject.addrecording(2, multipleEvents(2), false);
    end
    multiple.(name) = subject;
    
    r = multiple.(name).gettrainingrecordingindex;
    
    multiple.(names{s}).Modelblink = multiple.(names{s}).Recordings{r}.getmodelblink(30);
end

clear('names', 'rec', 'name', 'subject', 'r', 's')