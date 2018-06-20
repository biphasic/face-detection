%plot(fedeOn)
%hold on
%plot(fedeOff)
%plot(laurOn)
%plot(laurOff)
%plot(alexOn)
%plot(alexOff)

load('averages')

averageOn = fedeOn + alexOn + laurOn;
averageOn = averageOn / 3;
averageOff = fedeOff + alexOff + laurOff;
averageOff = averageOff / 3;

%on = plot(averageOn)
%on.LineWidth = 3;
%off = plot(averageOff)
%off.LineWidth = 3;

varianceOn = (fedeOn - averageOn).^2 + (laurOn - averageOn).^2 + (alexOn - averageOn).^2;
varianceOn = varianceOn / 3;
varianceOff = (fedeOff - averageOff).^2 + (laurOff - averageOff).^2 + (alexOff - averageOff).^2;
varianceOff = varianceOff / 3;

%var = plot(sqrt(varianceOff))
%var.LineWidth = 3;
%var2 = plot(sqrt(varianceOn))
%var2.LineWidth = 3;

x = 1:length(varianceOn);

filterResolution = 60;
movingAverageWindow = ones(1, filterResolution)/filterResolution;

filteredAverageOn = filter(movingAverageWindow, 1, averageOn);
filteredSigmaOn = filter(movingAverageWindow, 1, sqrt(varianceOn));
filteredAverageOff = filter(movingAverageWindow, 1, averageOff);
filteredSigmaOff = filter(movingAverageWindow, 1, sqrt(varianceOff));

hold on
%shadedErrorBar(x, averageOn, sqrt(varianceOn), 'lineprops', '-r')
%shadedErrorBar(x, averageOff, sqrt(varianceOff), 'lineprops', '-r')
shadedErrorBar(x, filteredAverageOn, filteredSigmaOn, 'lineprops', '-b')
shadedErrorBar(x, filteredAverageOff, filteredSigmaOff, 'lineprops', '-r')
