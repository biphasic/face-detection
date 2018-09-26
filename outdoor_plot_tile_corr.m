s = 1;
r = 2;
rec = outdoorSubjects(s).Recordings{r}.Eventstream;
i = 9;
j = 10;

modelBlink = outdoorSubjects(s).Modelblink;
tile_width = 19;
tile_height = 15;

eye = quick_correlation(outdoorSubjects(s).Recordings{r}.Grids{1}{i,j}, modelBlink.AverageOn, modelBlink.AverageOff, outdoorSubjects(s).AmplitudeScale, outdoorSubjects(s).BlinkLength);

correlationThreshold = 0.88;

figure 
stem(eye.ts, eye.activityOn/outdoorSubjects(s).AmplitudeScale);
hold on;
stem(eye.ts, -eye.activityOff/outdoorSubjects(s).AmplitudeScale);
plot([0 eye.ts(end)], [correlationThreshold correlationThreshold]);

windows = eye.ts(~isnan(eye.patternCorrelation));
disp(['Number of windows: ', num2str(length(windows))])
for i=eye.ts(~isnan(eye.patternCorrelation))
    a = area([i-outdoorSubjects.BlinkLength i], [eye.patternCorrelation(eye.ts == i) eye.patternCorrelation(eye.ts == i)]);
    a.FaceAlpha = 0.1;
    if eye.patternCorrelation(eye.ts == i) > correlationThreshold
        a.FaceColor = 'yellow';
        a.FaceAlpha = 0.5;
    end
end