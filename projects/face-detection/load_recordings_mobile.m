tic
for n = 3:3
    mobileEventsGregor = load_eventstream(['/home/gregorlenz/Recordings/face-detection/mobile/gregor/',num2str(n),'/3-filtered.es']);
    disp(['loaded recording number ', num2str(n), ' for all subjects'])
end
toc