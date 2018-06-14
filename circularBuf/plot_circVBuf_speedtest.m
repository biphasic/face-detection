clear all;
lso = {'-'; '--'; ':'; '-.'}; % define a line style order
  
notests     = 10;  % number of tests for the exact same setting 
stepKBytes  = 32; % number of kbytes (x-axis) between each test setup

vecSz       = 8;
maxBufMBytes= 4;

% 0 (default): constant time for append, because of double buffer.
% 1          : simply copy always all
% 2          : no double buffer. Copy all if end of buffer reached.
% 3          : no double buffer. Create new buffer with copy if end of buffer reached.
for appendType=0:1
    figure;
    hold on;
    title({'speedtest for circular buffer: copy-all-always vs. circVBuf',['(appendType=' num2str(appendType) ')']});
    X = [];
    for tid=1:maxBufMBytes
        
        % tid * mbytes
        bufSz  = (tid *1024 *1024) /(vecSz*8); % tid = no. mbytes
        stepSz = (stepKBytes*1024) /(vecSz*8); %  128 kByte steps
        
        testSz = 1:stepSz:bufSz;
        wtimes = zeros(2,size(testSz,2),'double');
        for s=1:notests
            wtimes_once = circVBuf_speedtest(bufSz, vecSz, stepSz, appendType);
            wtimes = wtimes + wtimes_once;
        end
        wtimes = wtimes ./notests;
        
        cnt = 1;
        for ix=testSz
            X(cnt) = ix* (vecSz*8) /1024; % X in kBytes
            cnt = cnt +1;
        end
        
        plot(X,wtimes(1,:),'Color', 'red',  'LineStyle', lso{tid}); %, 'Marker', 'x');
        plot(X,wtimes(2,:),'Color', 'blue', 'LineStyle', lso{tid}); %, 'Marker', 'o');
    end
    
    for mb=1:maxBufMBytes
        cirvVBuf{mb}  = [num2str(mb) ' mbyte (circVBuf,appendType=' num2str(appendType),')' ];
        copyAlways{mb}= [num2str(mb) ' mbyte (copy-always-all)'];
    end
    
    if(maxBufMBytes == 4)
        legend( cirvVBuf{1}, copyAlways{1}, ...
            cirvVBuf{2}, copyAlways{2}, ...
            cirvVBuf{3}, copyAlways{3}, ...
            cirvVBuf{4}, copyAlways{4}, ...
            'Location','SouthEast')
    else
        disp('update legend on your own');
    end
    
    xlabel('size of appended vectors [kByte]');
    ylabel('time to append vectors [sec]');
    set(gca,'XTick',0:512:(bufSz*(vecSz*8)/1024));
end

