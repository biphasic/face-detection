%%% variance across blinks of recent subject %%%
averageOn = absMasterOn;
averageOff = absMasterOff;
varianceOn = zeros(1, length(averages{1}));
varianceOff = varianceOn;
len = length(averages(1,:));
for i = 1:len
    varianceOn = varianceOn + (averages{1, i} - averageOn).^2 / len;
    varianceOff = varianceOff + (averages{2, i} - averageOff).^2 / len;
end

x = 1:length(varianceOn);

filterResolution = length(averageOn) / 100;
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



%%%variance across subjects%%%

subjectAverageOn = (fedeOn + laureOn + alexOn) / 3;
subjectAverageOff = (fedeOff + laureOff + alexOff) / 3;
subjectVarianceOn = ((fedeOn - subjectAverageOn).^2 + (laureOn - subjectAverageOn).^2 + (alexOn - subjectAverageOn).^2)/3;
subjectVarianceOff = ((fedeOff - subjectAverageOff).^2 + (laureOff - subjectAverageOff).^2 + (alexOff - subjectAverageOff).^2)/3;

filterResolution = length(subjectAverageOn) / 100;
movingAverageWindow = ones(1, filterResolution)/filterResolution;

subjectFilteredAverageOn = filter(movingAverageWindow, 1, subjectAverageOn);
subjectFilteredSigmaOn = filter(movingAverageWindow, 1, sqrt(subjectVarianceOn));
subjectFilteredAverageOff = filter(movingAverageWindow, 1, subjectAverageOff);
subjectFilteredSigmaOff = filter(movingAverageWindow, 1, sqrt(subjectVarianceOff));

hold on
%shadedErrorBar(x, subjectAverageOn, sqrt(subjectVarianceOn), 'lineprops', '-r')
%shadedErrorBar(x, subjectAverageOff, sqrt(subjectVarianceOff), 'lineprops', '-r')
shadedErrorBar(x, subjectFilteredAverageOn, subjectFilteredSigmaOn, 'lineprops', '-g')
shadedErrorBar(x, subjectFilteredAverageOff, subjectFilteredSigmaOff, 'lineprops', '-y')

