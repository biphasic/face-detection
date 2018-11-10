tic
names = {'laure', 'kevin', 'francesco', 'gregor'};
recordingsOutdoor = [];
for n = 1:length(names)
    name = names{n};
    for r = 1:3
        if strcmp(name, 'kevin')
            path = ['~/Recordings/face-detection/outdoor/', name, '/converted/', num2str(r),'.es'];
        else
            path = ['~/Recordings/face-detection/outdoor/', name, '/converted/', num2str(r),'-filtered.es'];
        end
        if exist(path, 'file') == 2 %&& isfield(recordingsOutdoor, name) && isempty(recordingsOutdoor.(name)(r))
            recordingsOutdoor.(name)(r) =  load_eventstream(path);
        else
            continue;
        end
        disp(['loaded recording number ', num2str(r), ' for subject ', name])
    end
end
clear('names', 'name', 'path', 'n', 'r');
toc