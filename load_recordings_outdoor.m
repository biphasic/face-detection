tic
for n = 1:3
    outdoorEventsLaure(n) = load_eventstream(['/home/gregorlenz/Recordings/face-detection/outdoor/laure/converted/',num2str(n),'-filtered.es']);
    %outdoorEventsKevin(n) = load_eventstream(['/home/gregorlenz/Recordings/face-detection//outdoor/kevin/converted/',num2str(n),'.es']);
    %outdoorEventsFrancesco(n) = load_eventstream(['/home/gregorlenz/Recordings/face-detection//outdoor/francesco/converted/',num2str(n),'-filtered.es']);
    disp(['loaded recording number ', num2str(n), ' for all subjects'])
end
toc