tic
names = {'fede', 'alex', 'laure', 'laurent', 'pe', 'mylene', 'gregor', 'suzon'};

for n = 1:length(names)
    name = names{n};
    for r = 1:3
        path = ['~/Recordings/face-detection/indoor/', name, '/run', num2str(r),'.es'];
        if exist(path, 'file') == 2 && isfield(recordings.indoor, name) && isempty(recordings.indoor.(name)(r))
            recordings.indoor.(name)(r) =  load_eventstream(path);
        else 
            continue;
        end
        disp(['loaded recording number ', num2str(r), ' for subject ', name])
    end
end
toc