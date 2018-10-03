subjects = outdoorSubjects;
s = 3;
r = 1;

offGrid = 1;

if offGrid == 1
    rec = subjects(s).Recordings{r}.Eventstream;
    tileWidth = 19;
    tileHeight = 15;
    blinkCoordinates = subjects(s).Recordings{r}.Left.Location;
    eye = crop_spatial(rec, blinkCoordinates(1)-tileWidth/2, blinkCoordinates(2)-tileHeight/2, tileWidth, tileHeight);
    eye = activity(eye, 50000, true);
else
    grid = 2;
    i = 7;
    j = 10;
    eye = subjects(s).Recordings{r}.Grids{grid}{i,j};
end

modelBlink = subjects(s).Modelblink;

eye = quick_correlation(eye, modelBlink.AverageOn, modelBlink.AverageOff, subjects(s).AmplitudeScale, subjects(s).BlinkLength);
timeScale = 10;
continuum = shannonise(eye, timeScale);

correlationThreshold = 0.88;

figure 
plot([0 eye.ts(end)], [correlationThreshold correlationThreshold]);
hold on;

if 1 == 2
    stem(eye.ts, eye.activityOn/subjects(s).AmplitudeScale);
    stem(eye.ts, -eye.activityOff/subjects(s).AmplitudeScale);
else
    plot(continuum.ts*timeScale, continuum.activityOn/subjects(s).AmplitudeScale);
    plot(continuum.ts*timeScale, -continuum.activityOff/subjects(s).AmplitudeScale);
end

windows = eye.ts(~isnan(eye.patternCorrelation));
disp(['Number of windows: ', num2str(length(windows))])
for i=eye.ts(~isnan(eye.patternCorrelation))
    a = area([i-subjects(s).BlinkLength i], [eye.patternCorrelation(eye.ts == i) eye.patternCorrelation(eye.ts == i)]);
    a.FaceAlpha = 0.1;
    if eye.patternCorrelation(eye.ts == i) > correlationThreshold
        a.FaceColor = 'yellow';
        a.FaceAlpha = 0.5;
    end
end