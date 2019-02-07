tic
names = {'gregor'};
recordingsPose = [];
for n = 1:length(names)
    name = names{n};
    for r = 4:4
        path = ['~/Recordings/face-detection/pose-variation/', name, '/', num2str(r), '/', num2str(r),'-filtered-1000.es'];
        if exist(path, 'file') == 2 %&& isempty(recordingsIndoor.(name)(r))
            recordingsPose.(name)(r) =  load_eventstream(path);
        else
            continue;
        end
        disp(['loaded recording number ', num2str(r), ' for subject ', name])
    end
end
clear('names', 'name', 'path', 'n', 'r');
toc