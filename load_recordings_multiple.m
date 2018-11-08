tic
for n = 1:4
    multipleEvents(n) = load_eventstream(['/home/gregorlenz/Recordings/face-detection/multiple/felix-kevin-gregor/',num2str(n),'/v1-filtered.es']);
    disp(['loaded recording number ', num2str(n), ' for all subjects'])
end
toc