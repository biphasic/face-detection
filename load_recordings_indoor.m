tic
for n = 1:3
    eventsFede(n) = load_eventstream(['~/Recordings/face-detection/Fede/run',num2str(n),'.es']);
    eventsAlex(n) = load_eventstream(['~/Recordings/face-detection/Alex/run',num2str(n),'.es']);
    eventsLaure(n) = load_eventstream(['~/Recordings/face-detection/Laure/run',num2str(n),'.es']);
    disp(['loaded recording number ', num2str(n), ' for all subjects'])
end
toc

%path = fullfile('~', 'Recordings', 'face-detection');
%
%path = fullfile(path, subject);
%if ~exist('events', 'var') || ~exist('loadedSubject', 'var') || ~strcmp(loadedSubject, subject)
%tic
%events = load_eventstream(path);
%toc
%loadedSubject = subject;
%end