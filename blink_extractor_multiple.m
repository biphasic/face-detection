if ~exist('multipleEvents', 'var')
    load('recordingsMultiple.mat')
end
names = {'jpmarcogregor'};
multiple = Collection('multiple');
for s = 1:numel(names)
    if s == 1
        disp('jp-marco-jpmarcogregor/run4.es')
        jpmarcogregor = Subject(names{s}, multiple);
        jpmarcogregor.BlinkLength = 300000;
        n = 6;
        jpmarcogregor.addrecording(n, multipleEvents(n), true);
        jpmarcogregor.Recordings{n}.Center.Location = [135 119];
        jpmarcogregor.Recordings{n}.Center.Times = [1529000     32031200];
        jpmarcogregor.Recordings{n}.Left.Location = [103 165];
        jpmarcogregor.Recordings{n}.Left.Times = [24576445];
        jpmarcogregor.Recordings{n}.Left.AmplitudeScaleScale = 0.2;
        jpmarcogregor.Recordings{n}.Right.Location =  [202 123];
        jpmarcogregor.Recordings{n}.Right.Times = [42568445];
        jpmarcogregor.Recordings{n}.Right.AmplitudeScaleScale = 2;
        jpmarcogregor.CorrelationThreshold = 0.88;
        addprop(multiple, jpmarcogregor.Name);
        multiple.(names{s}) = jpmarcogregor;
    end
    
    r = multiple.(names{s}).gettrainingrecordingindex;
    
    multiple.(names{s}).Modelblink = multiple.(names{s}).Recordings{r}.getmodelblink(30);
        
    clear(names{s}, 'r', 'm', 'ax', 's')
end