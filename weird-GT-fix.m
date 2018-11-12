rec = scale.gregor.Recordings{6};
mask = and(rec.GT.ts > 12920000, rec.GT.ts < 26240000);
maskTracker = and(rec.Eventstream.ts > 12920000, rec.Eventstream.ts < 26240000);
unityx = (rec.Eventstream.leftTracker.x(maskTracker) + rec.Eventstream.rightTracker.x(maskTracker))/2;
unityy = (rec.Eventstream.leftTracker.y(maskTracker) + rec.Eventstream.rightTracker.y(maskTracker))/2;
unityXNoise = awgn(unityx, 10, 'measured');
unityYNoise = awgn(unityy, 10, 'measured');

filterResolution = floor(length(unityx)/ 50);
movingAverageWindow = ones(1, filterResolution) / filterResolution;
unityXFiltered = filter(movingAverageWindow, 1, unityx-unityx(1));
unityYFiltered = filter(movingAverageWindow, 1, unityy-unityy(1));

plot(rec.Eventstream.ts(maskTracker), unityx)
hold on
plot(rec.Eventstream.ts(maskTracker), unityXFiltered+unityx(1))
plot(rec.Eventstream.ts(maskTracker), unityy)
plot(rec.Eventstream.ts(maskTracker), unityYFiltered+unityy(1))


testTS = rec.Eventstream.ts(maskTracker);
testTS = testTS(1:832:end-200);
testX= unityXFiltered(1:832:end-200)+unityx(1);
testY= unityYFiltered(1:832:end-200)+unityy(1);
plot(testTS, testX)

rec.GT.x(mask) = testX;
rec.GT.y(mask) = testY;


%rec.GT.x(mask) = 