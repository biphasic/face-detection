eventsFede = load_eventstream('~/Recordings/face-detection/Fede/run1.es');
disp('loaded Fedes recording');
eventsAlex = load_eventstream('~/Recordings/face-detection/Alex/run1.es');
disp('loaded Alexes recording');
eventsLaure = load_eventstream('~/Recordings/face-detection/Laure/run3.es');
disp('loaded Laures recording');

%path = fullfile('~', 'Recordings', 'face-detection');
%
%path = fullfile(path, subject);
%if ~exist('events', 'var') || ~exist('loadedSubject', 'var') || ~strcmp(loadedSubject, subject)
%tic
%events = load_eventstream(path);
%toc
%loadedSubject = subject;
%end