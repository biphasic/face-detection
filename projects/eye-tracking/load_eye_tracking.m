name = 'gregor';
d = 1;
r = 1;
path = ['~/Recordings/eye-tracking/', name, '/', num2str(d), '/', num2str(r),'-filtered-500.es'];

eyerecording = load_eventstream(path);