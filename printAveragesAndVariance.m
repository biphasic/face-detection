


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

