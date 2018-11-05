tic
names = {'fede', 'alex', 'laure', 'laurent', 'pe', 'mylene', 'gregor', 'suzon'};

for n = 1:length(names)
    name = names{n};
    for r = 1:3
        path = ['~/Recordings/face-detection/indoor/', name, '/run', num2str(r),'.es'];
        if exist(path, 'file') == 2 && isfield(recordingsIndoor, name) && isempty(recordingsIndoor.(name)(r))
            recordingsIndoor.(name)(r) =  load_eventstream(path);
        else
            continue;
        end
        disp(['loaded recording number ', num2str(r), ' for subject ', name])
    end
end
clear('names', 'name', 'path', 'n', 'r');
toc