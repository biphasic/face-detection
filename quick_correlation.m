function eye = quick_correlation(eye, onFilter, offFilter, amplitudeScale, slidingWindowWidth)
% apply sliding window on eventstream and store correlation results in
% substructure

allTimestamps = eye.ts;
allActivityOn = eye.activityOn;
allActivityOff = eye.activityOff;
len = length(allTimestamps);
eye.patternCorrelation = nan(1, len);

minimumDifference = slidingWindowWidth/6;
corrBufferScale = 100;
bufferSize = slidingWindowWidth/corrBufferScale;

filteredAverageOn = onFilter;
filteredAverageOff = offFilter;

bufferOn = zeros(1, length(allActivityOn));
bufferOff = zeros(1, length(allActivityOn));
skip = find(allTimestamps > 500000);
if ~isempty(skip)
    skip = skip(1);
else
    return;
end

bufferOnStart = skip;
bufferOffStart = skip;
lastPM = 0;
%columns = 0;

%tic
%loop over all events
for i = skip:len
    timestamp = allTimestamps(i);
    % add latest event to the buffer
    if isnan(allActivityOff(i))
        bufferOn(i) = 1;
    else
        bufferOff(i) = 1;
    end
    % remove events from buffer that are outside sliding window
    for j = bufferOnStart:(i-1)
        if allTimestamps(j) < (timestamp - slidingWindowWidth)
            bufferOn(j) = 0;
        else
            bufferOnStart = j;
            break;
        end
    end
    for j = bufferOffStart:(i-1)
        if allTimestamps(j) < (timestamp - slidingWindowWidth)
            bufferOff(j) = 0;
        else
            bufferOffStart = j;
            break;
        end
    end
 
    %tic
    if timestamp - lastPM >= minimumDifference
        nOn = nnz(bufferOn(bufferOnStart:i));
        if nOn > 30 && nOn < 300
            nOff = nnz(bufferOff(bufferOffStart:i));
            if  nOff > 20 && nOff < 200
                bufOn = zeros(1, slidingWindowWidth/corrBufferScale);
                bufOff = zeros(1, slidingWindowWidth/corrBufferScale);
                divisor = timestamp - slidingWindowWidth;
                % generate a 'time representation' rather than simply the events
                % and downscale to smaller buffer size
                for k=find(bufferOn == 1)
                    index = ceil(mod(allTimestamps(k), divisor)/corrBufferScale);
                    if index == 0
                        index = 1;
                    end
                    bufOn(index) = allActivityOn(k)/amplitudeScale;
                end
                for k=find(bufferOff == 1)
                    index = ceil(mod(allTimestamps(k), divisor)/corrBufferScale);
                    if index == 0
                        index = 1;
                    end
                    bufOff(index) = allActivityOff(k)/amplitudeScale;
                end
                samplesOn = filteredAverageOn .* (bufOn>0);
                samplesOff = filteredAverageOff .* (bufOff>0);
                resOn = xcorr(bufOn, samplesOn, 'coeff');
                resOff = xcorr(bufOff, samplesOff, 'coeff');
                eye.patternCorrelation(i) = resOn(bufferSize)*resOff(bufferSize);
                lastPM = timestamp;
            end
        end
    end
    %t = t+toc;
end
%toc

end