subjects = outdoorSubjects;
s = 1;
r = 2;

rec = subjects(s).Recordings{r}.Eventstream;
tileWidth = 19;
tileHeight = 15;

figure
hold on
for l=1:3
    if l == 1
        loc = 'Center';
    elseif l == 2
        loc = 'Left';
    elseif l == 3
        loc = 'Right';
    else
    end
    
    blinkCoordinates = subjects(s).Recordings{r}.(loc).Location;
    eye = crop_spatial(rec, blinkCoordinates(1)-tileWidth/2, blinkCoordinates(2)-tileHeight/2, tileWidth, tileHeight);
    eye = activity(eye, 50000, true);

    timeScale = 10;
    continuum = shannonise(eye, timeScale);

    ax = subplot(3, 1, l);
    title(ax, loc)
    %plot(continuum.ts(mask)*timeScale, continuum.activityOn(mask)/subjects(s).AmplitudeScale);
    %plot(continuum.ts(mask)*timeScale, continuum.activityOff(mask)/subjects(s).AmplitudeScale);
    ylim([0 3])
    %mask = continuum.ts < (15000000/timeScale);
    opts1={'FaceAlpha', 0.7, 'FaceColor', [0    0.4470    0.7410]};%blau
    opts2={'FaceAlpha', 0.7, 'FaceColor', [0.8500    0.3250    0.0980]};%rot
    opts3={'FaceAlpha', 0.7, 'FaceColor', [0.4660    0.6740    0.1880]};%grün

    if l == 1
        mask = continuum.ts < (15000000/timeScale);
    elseif l == 2
        mask = and(continuum.ts > (10000000/timeScale), continuum.ts < (25000000/timeScale));
    elseif l == 3
        mask = continuum.ts > (20000000/timeScale);
    else
    end
    z = zeros(1, numel(continuum.activityOn(mask)));
    x = continuum.ts(mask)*timeScale;
    y1 = continuum.activityOff(mask)/subjects(s).AmplitudeScale;
    y2 = continuum.activityOn(mask)/subjects(s).AmplitudeScale;
    fill_between(x, y1, y2, y1 < y2, opts2{:});
    fill_between(x, z, y1, y1 > z, opts1{:});
    %fill_between(x, z, y2, y2 > z, opts2{:});
end
