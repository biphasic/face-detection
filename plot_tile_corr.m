subjects = outdoorSubjects;
s = 2;
r = 2;

names = {'laure', 'kevin', 'francesco'};

offGrid = 1;

if offGrid == 1
    rec = subjects.(names{s}).Recordings{r}.Eventstream;
    tileWidth = 19;
    tileHeight = 15;
    blinkCoordinates = subjects.(names{s}).Recordings{r}.Center.Location;
    eye = crop_spatial(rec, blinkCoordinates(1)-tileWidth/2, blinkCoordinates(2)-tileHeight/2, tileWidth, tileHeight);
    eye = activity(eye, 50000, true);
else
    grid = 2;
    i = 7;
    j = 10;
    eye = subjects.(names{s}).Recordings{r}.Grids{grid}{i,j};
end

modelBlink = subjects.(names{s}).Modelblink;

eye = quick_correlation(eye, modelBlink.AverageOn, modelBlink.AverageOff, subjects.(names{s}).AmplitudeScale, subjects.(names{s}).BlinkLength);
timeScale = 10;
continuum = shannonise(eye, timeScale);

correlationThreshold = 0.88;

figure 
plot([0 eye.ts(end)], [correlationThreshold correlationThreshold]);
hold on;

if 1 == 2
    stem(eye.ts, eye.activityOn/subjects.(names{s}).AmplitudeScale);
    stem(eye.ts, -eye.activityOff/subjects.(names{s}).AmplitudeScale);
else
    plot(continuum.ts*timeScale, continuum.activityOn/subjects.(names{s}).AmplitudeScale);
    plot(continuum.ts*timeScale, continuum.activityOff/subjects.(names{s}).AmplitudeScale);
end

windows = eye.ts(~isnan(eye.patternCorrelation));
disp(['Number of windows: ', num2str(length(windows))])
for i=eye.ts(~isnan(eye.patternCorrelation))
    a = area([i-subjects.(names{s}).BlinkLength i], [eye.patternCorrelation(eye.ts == i) eye.patternCorrelation(eye.ts == i)]);
    a.FaceAlpha = 0.1;
    if eye.patternCorrelation(eye.ts == i) > correlationThreshold
        a.FaceColor = 'yellow';
        a.FaceAlpha = 0.5;
    end
end