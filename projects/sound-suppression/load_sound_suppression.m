name = 'tests';
d = 2;
r = 1;
path = ['~/Recordings/sound-suppression/', name, '/', num2str(d), '/', num2str(d),'-cut-filtered-10000.es'];

soundsuppressionrecording = load_eventstream(path);