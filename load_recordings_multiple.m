tic
for n = 6:6
    multipleEvents(n) = load_eventstream(['/home/gregorlenz/Recordings/face-detection/multiple/jp-marco-gregor/',num2str(n),'/v1-filtered.es']);
    disp(['loaded recording number ', num2str(n), ' for all subjects'])
end
toc