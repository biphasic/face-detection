rec = eventsLaure;
amplitudeScale = 73;
i = 5;
j = 8;
filterOn = filteredAverageOn;
filterOff = filteredAverageOff;
tile_width = 19;
tile_height = 15;
eye = crop_spatial(rec, (i-1) * tile_width, (j-1) * tile_height, tile_width, tile_height);
eye = activity(eye, 50000, true);
tic
eye = quick_correlation(eye, filterOn, filterOff, amplitudeScale);
toc

slidingWindowWidth = 300000;

correlationThreshold = 0.88;

figure 
stem(eye.ts, eye.activityOn/amplitudeScale);
hold on;
stem(eye.ts, -eye.activityOff/amplitudeScale);
plot([0 eye.ts(end)], [correlationThreshold correlationThreshold]);

windows = eye.ts(~isnan(eye.patternCorrelation));
disp('number of windows: ')
length(windows)
for i=eye.ts(~isnan(eye.patternCorrelation))
    a = area([i-slidingWindowWidth i], [eye.patternCorrelation(eye.ts == i) eye.patternCorrelation(eye.ts == i)]);
    a.FaceAlpha = 0.1;
    if eye.patternCorrelation(eye.ts == i) > correlationThreshold
        a.FaceColor = 'yellow';
        a.FaceAlpha = 0.5;
    end
end