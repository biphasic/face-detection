if ~exist('scaleEventsGregor', 'var')
    load('recordingsScale.mat')
end
names = {'gregor'};
scale = Collection('scale');
for s = 1:numel(names)
    if s == 1
        disp('Gregor/run6.es')
        gregor = Subject(names{s}, scale);
        gregor.BlinkLength = 300000;
        gregor.addrecording(6, scaleEventsGregor, true);
        gregor.Recordings{6}.Center.Location = [129 131];
        gregor.Recordings{6}.Center.Times = [1529000     3231200];
        gregor.Recordings{6}.Left.Location = [103 165];
        gregor.Recordings{6}.Left.Times = [24576445];
        gregor.Recordings{6}.Left.ActivityDecayConstant = 50000;
        gregor.Recordings{6}.Left.AddConstant = 0.2;
        gregor.Recordings{6}.Right.Location =  [202 123];
        gregor.Recordings{6}.Right.Times = [42568445];
        gregor.Recordings{6}.Right.ActivityDecayConstant = 50000;
        gregor.Recordings{6}.Right.AddConstant = 2;
        %gregor.Recordings{6}.Left.TileSizes = gregor.Recordings{6}.TileSizes * 2;
        %gregor.Recordings{6}.Right.TileSizes = gregor.Recordings{6}.TileSizes * 2 / 3;
        gregor.CorrelationThreshold = 0.88;
        gregor.addrecording(2, indoorEventsFede(2), false);
        gregor.addrecording(3, indoorEventsFede(3), false);
        addprop(scale, gregor.Name);
        scale.(names{s}) = gregor;
    end
    
    r = scale.(names{s}).gettrainingrecordingindex;
    
    scale.(names{s}).Modelblink = scale.(names{s}).Recordings{r}.getmodelblink(30);
        
    clear(names{s}, 'r', 'm', 'ax', 's')
end