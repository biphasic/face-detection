tic
for n = 6:6
    scaleEventsGregor = load_eventstream(['/home/gregorlenz/Recordings/face-detection/scale/',num2str(n),'/v1-filtered.es']);
    disp(['loaded recording number ', num2str(n), ' for all subjects'])
end
toc