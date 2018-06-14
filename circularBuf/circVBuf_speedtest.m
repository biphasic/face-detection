function wtimes = circVBuf_speedtest(bufferSz, vectorLen, stepSize, appendType)

% create a circular vector buffer2
cvbuf1 = circVBuf(int64(bufferSz),int64(vectorLen),appendType);
cvbuf2 = nan(bufferSz,vectorLen,'double');

% create vectors to append
vecs = rand(bufferSz,vectorLen,'double');

% fill buffer once to avoid first touch speed-loss
cvbuf1.append(vecs);
cvbuf1.append(vecs);
cvbuf2 = [cvbuf2(bufferSz+1:end,1:vectorLen); vecs(1:bufferSz,1:vectorLen) ];

% to the speedtest
cnt = 1;
testSz = 1:stepSize:bufferSz;
wtimes = zeros(2,size(testSz,2),'double');
for ix=testSz
    
    % create vectors to append
    vecs = rand(ix,vectorLen,'double');
    
    % append vectors to circular buffer
    tic
        cvbuf1.append(vecs);
        %newMean = mean(cvbuf1.raw(cvbuf1.new:cvbuf1.lst,3));  % do some operation
    wtimes(1,cnt) = toc;

    % append vectors to circular buffer
    tic    
      cvbuf2 = [cvbuf2(ix+1:end,:); vecs(1:ix,:) ];
      %newMean = mean(cvbuf2(end-ix:end)); % do some operation
    wtimes(2,cnt) = toc;
    
    cnt = cnt +1;    
end

end
