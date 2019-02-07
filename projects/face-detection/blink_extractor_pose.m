if ~exist('recordingsPose', 'var')
    disp('loading compressed recordings from file...')
    load('recordingsPose.mat')
end
names = fieldnames(recordingsPose);
pose = Collection('pose');
for s = 1:numel(names)
    name = names{s};
    addprop(pose, name);
    subject = Subject(name, 0.88, pose);
    if strcmp(name, 'gregor')
        subject.addrecording(4, recordingsPose.(name)(4), true);
        subject.Recordings{4}.Center.Location = [272 284];
        subject.Recordings{4}.Center.Times = [2562000     5345220];
        subject.Recordings{4}.Dimensions = [640 480];
        %subject.addrecording(5, recordingsPose.(name)(5), true);
        %subject.Recordings{5}.Center.Location = [270 300];
        %subject.Recordings{5}.Center.Times = [2562000 ];
        %subject.Recordings{5}.Dimensions = [640 480];
    else
        for r = 1:length(recordingsPose.(name))
            subject.addrecording(r, recordingsPose.(name)(r), false);
        end
    end
    pose.(name) = subject;
    
    r = pose.(name).gettrainingrecordingindex;
    if r ~= 0
        pose.(name).Modelblink = pose.(name).Recordings{r}.getmodelblink(30);
    end
end

clear('names', 'rec', 'name', 'subject', 'r', 's')