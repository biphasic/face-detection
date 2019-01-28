tic
names = {'fede', 'alex', 'laure', 'laurent', 'pe', 'mylene', 'gregor', 'suzon'};
recordingsIndoor = [];
for n = 1:length(names)
    name = names{n};
    for r = 1:3
        path = ['~/Recordings/face-detection/indoor/', name, '/', num2str(r), '/run', num2str(r),'.es'];
        if exist(path, 'file') == 2 %&& isempty(recordingsIndoor.(name)(r))
            recordingsIndoor.(name)(r) =  load_eventstream(path);
        else
            continue;
        end
        disp(['loaded recording number ', num2str(r), ' for subject ', name])
    end
end
clear('names', 'name', 'path', 'n', 'r');
toc