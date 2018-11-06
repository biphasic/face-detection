if ~exist('recordingsIndoor', 'var')
    load('recordingsIndoor.mat')
end
names = fieldnames(recordingsIndoor);
indoor = Collection('indoor');
for s = 1:numel(names)
    name = names{s};
    addprop(indoor, name);
    subject = Subject(name, indoor);
    if strcmp(name, 'fede')
        subject.addrecording(1, recordingsIndoor.(name)(1), true);
        subject.Recordings{1}.Center.Location = [152 131];
        subject.Recordings{1}.Left.Location = [ 62 125];
        subject.Recordings{1}.Right.Location =  [228 132];
        subject.Recordings{1}.Center.Times = [2432000     5125600     6771680     9025140    10915620];
        subject.Recordings{1}.Left.Times = [16210115    17043535    19352235    20343515];
        subject.Recordings{1}.Right.Times = [31274790    36131610];
        subject.addrecording(2, recordingsIndoor.(name)(2), false);
        subject.addrecording(3, recordingsIndoor.(name)(3), false);
    elseif strcmp(name, 'alex')
        subject.addrecording(1, recordingsIndoor.(name)(1), true);
        subject.Recordings{1}.Center.Location = [152 167];
        subject.Recordings{1}.Left.Location =   [ 82 144];
        subject.Recordings{1}.Right.Location =  [223 146];
        subject.Recordings{1}.Center.Times = [1012000     2016300     6191880];
        subject.Recordings{1}.Left.Times = [13546240    14769500];
        subject.Recordings{1}.Right.Times = [30229640    32723700    34745280];
        subject.addrecording(2, recordingsIndoor.(name)(2), false);
        subject.addrecording(3, recordingsIndoor.(name)(3), false);
    elseif strcmp(name, 'laure')
        subject.addrecording(3, recordingsIndoor.(name)(3), true);
        subject.Recordings{3}.Center.Location = [153 121];
        subject.Recordings{3}.Left.Location =   [102 114];
        subject.Recordings{3}.Right.Location =  [203 119];
        subject.Recordings{3}.Center.Times = [2940000     6918660];
        subject.Recordings{3}.Left.Times = [15462420    17777200];
        subject.Recordings{3}.Right.Times = [28000295    29189715];
        subject.CorrelationThreshold = 0.9;
        subject.addrecording(1, recordingsIndoor.(name)(1), false);
        subject.addrecording(2, recordingsIndoor.(name)(2), false);
    elseif strcmp(name, 'suzon')
        subject.addrecording(1, recordingsIndoor.(name)(1), false);
        rec = subject.Recordings{1};
        rec.Center.Location = [132 138];
        rec.Left.Location = [74 124];
        rec.Right.Location = [189 125];
    else
        for r = 1:length(recordingsIndoor.(name))
            subject.addrecording(r, recordingsIndoor.(name)(r), false);
        end
    end
    indoor.(name) = subject;
    
    r = indoor.(name).gettrainingrecordingindex;
    if r ~= 0
        indoor.(name).Modelblink = indoor.(name).Recordings{r}.getmodelblink(30);
    end
end

clear('names', 'rec', 'name', 'subject', 'r', 's')