tic
names = {'laure', 'kevin', 'francesco', 'gregor', 'gregor2', 'ricardo', 'jm', 'alex', 'omar'};
if ~exist('recordingsOutdoor', 'var')
    recordingsOutdoor = [];
end
for n = 1:length(names)
    name = names{n};
    if ~isfield(recordingsOutdoor, name)
        recordingsOutdoor.(name) = [];
    end
    for r = 1:6
        %if strcmp(name, 'kevin')
            path = ['~/Recordings/face-detection/outdoor/', name, '/converted/', num2str(r),'.es'];
        %else
            %path = ['~/Recordings/face-detection/outdoor/', name, '/converted/', num2str(r),'-filtered.es'];
        %end
        if exist(path, 'file') == 2 && size(recordingsOutdoor.(name), 2) < r
            if r == 1
                recordingsOutdoor.(name) = load_eventstream(path);
            else
                recordingsOutdoor.(name)(r) =  load_eventstream(path);
            end
        else
            continue;
        end
        disp(['loaded recording number ', num2str(r), ' for subject ', name])
    end
end
clear('names', 'name', 'path', 'n', 'r');
toc