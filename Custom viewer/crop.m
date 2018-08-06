%% Selection and cropping %%%%%%%%%%%%%%%%%%%%%%%%
% Creates a structure 's' from a croped *.dat file
% The fields are: 'ts','x','y','p'
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

field1 = 'ts';
field2 = 'x';
field3 = 'y';
field4 = 'p';
value1 = zeros(x2-x1,1);
value2 = zeros(x2-x1,1);
value3 = zeros(x2-x1,1);
value4 = zeros(x2-x1,1);
s = struct(field1,value1,field2,value2,field3,value3,field4,value4);
k=1;
for i=x1:x2
    s.ts(k)=td_data.ts(i);
    s.x(k)=td_data.x(i);
    s.y(k)=td_data.y(i);
    s.p(k)=td_data.p(i);
    k=k+1;
end

close all


%% Spatio temporal filtering %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Filtering of events depending on the activity of the local
% neighbors over a time window 'win'
% For a 4x4 neighborhood uncomment the lines inside the if loops
% and comment the active lines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Time window in microsecond
win=2000;

%Output structure, the fileds are : 'ts','x','y','p'
noise_free = struct(field1,value1,field2,value2,field3,value3,field4,value4);

for i=1:numel(s.ts)-1
    ind=0;
    for k=i+1:numel(s.ts)
        if s.ts(k)<(s.ts(i)+win) %If it belongs to the time window
            if s.x(k)==(s.x(i)-1)||s.x(k)==(s.x(i)+1)||s.x(k)==(s.x(i)) %If it belongs to the neighborhood
           % if s.x(k)==(s.x(i)-2)||s.x(k)==(s.x(i)+2)||s.x(k)==(s.x(i))||s.x(k)==(s.x(i)-1)||s.x(k)==(s.x(i)-1)
                if s.y(k)==(s.y(i)-1)||s.y(k)==(s.y(i)+1)||s.y(k)==(s.y(i)) %If it belongs to the neighborhood
               % if s.y(k)==(s.y(i)-2)||s.y(k)==(s.y(i)+2)||s.y(k)==(s.y(i))||s.y(k)==(s.y(i)-1)||s.y(k)==(s.y(i)-1)
                    if s.y(k)==s.y(i)&&s.x(k)==s.x(i) %If it's not the same pixel
                    else
                        noise_free.ts(i)=s.ts(i); %We keep it!!
                        noise_free.x(i)=s.x(i);
                        noise_free.y(i)=s.y(i);
                        noise_free.p(i)=s.p(i);
                        break
                    end
                end
            end
        end
    end
    a=numel(s.ts)-i %To give you an idea of how long it remains to compute
end


bob=noise_free.ts(noise_free.ts~=0);
noise_free_corr = struct(field1,numel(bob),field2,numel(bob),field3,numel(bob),field4,numel(bob));
noise_free_corr.ts=noise_free.ts(noise_free.ts~=0);
noise_free_corr.x=noise_free.x(noise_free.x~=0);
noise_free_corr.y=noise_free.y(noise_free.y~=0);
noise_free_corr.p=noise_free.p(noise_free.p~=0);
