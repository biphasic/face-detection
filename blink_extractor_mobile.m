if ~exist('mobileEventsGregor', 'var')
    load('recordingsMobile.mat')
end
names = {'gregor'};
mobile = Collection('mobile');
for s = 1:numel(names)
    if s == 1
        disp('Gregor/run3.es')
        gregor = Subject(names{s}, 0.88, mobile);
        gregor.BlinkLength = 250000;
        gregor.addrecording(3, mobileEventsGregor, true);
        gregor.Recordings{3}.Left.Location = [102 149];
        gregor.Recordings{3}.Left.Times = [1546000     2629260     3809260];
        gregor.Recordings{3}.Right.Location = [198 153];
        gregor.Recordings{3}.Right.Times = [1546000     2629260     3809260];
        addprop(mobile, gregor.Name);
        mobile.(names{s}) = gregor;
    end
    
    r = mobile.(names{s}).gettrainingrecordingindex;
    
    mobile.(names{s}).Modelblink = mobile.(names{s}).Recordings{r}.getmodelblink(30);
        
    clear(names{s}, 'r', 'm', 'ax', 's')
end