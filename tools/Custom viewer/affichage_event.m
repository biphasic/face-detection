function [img]= affichage_event(filename, frame_time)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%This function displays td events from an Atis file. It allows you to
%recompute the events from the corresponding aps file if needed. It also
%allows the user to selct only part of the recording.
%
% Inputs are optional:
%               - filename : should be a string file corresponding 
%                            to a '*_td.dat' file
%               - frame_time : time of a reconstructed frame in �s 
%
% Required m files:
%               - load_atis_data.m
%               - simu_event_filter_x.m
%               - load_atis_aps.m
%               - displayIm3d.m
%
%Only events can be displayed.
%xavier.berthelon@inserm.fr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%% Selection of the *_td.mat file
if nargin<1,
    [filename,~,~]=uigetfile('*.es','Select your data file');
    
%     if filename==0 
%         return; 
%     end
end
td_data=load_eventstream(filename);
%td_data=load_atis_data('OCT3_td.dat'); %test

%%%%%% Recomputation of events from gray levels 
answer1=menu('Would you like to recompute events from the recording?','Yes','No');
if answer1==1
    answer4=menu('Is the corresponding APS file in the same directory?','Yes','No');
    if answer4==1
        filename=strrep(filename,'_td','_aps');
    else
    [filename,~,~]=uigetfile('*_aps.dat','Find and select your aps file');
    end
    prompt='Enter value for alpha_up (positive events filtering), default is 0.2:';
    alpha_up=input(prompt);
    prompt='Enter value for alpha_down (negative events filtering), default is 0.03:';
    alpha_down=input(prompt);
    td_data=simu_events_filter_x(filename, alpha_up, alpha_down);
end

%%%%%% Selection of a portion fo the recording 
answer2=menu('Would you like to select only part of the recording?','Yes','No');
if answer2==1
    plot(td_data.ts)
        title('Please select the limits of your recording (two points)')
        xlabel('Time in �s')
        ylabel('Number of events')
    [x1,~]=getpts;
    [x2,~]=getpts;
    x1=floor(x1);
    x2=floor(x2);
    close all;
else
    x1=1;
    x2=numel(td_data.ts);
end


%%%%%% Initialisation 
ind_t_start=x1;
t_start=td_data.ts(ind_t_start);
ind_t_end=x2;
t_end=td_data.ts(ind_t_end);

%%%%%% Frame time input
if nargin<=1,
prompt='Duration of you reconstructed "frames" in �s:';
frame_time=input(prompt); %in �s
end
duration=td_data.ts(ind_t_end)-td_data.ts(ind_t_start);
slice=floor(duration/frame_time);

%%%%%% Window display depending on wether reconstruction was performed
if answer1==1
        sx = 305;
        sy = 241;
else
        sx = 304;
        sy = 240;
end
img = zeros(sy,sx,slice);


start=ind_t_start;
end_time = find(td_data.ts>=t_start+frame_time,1);

%%%%%% Algo for frame creation from events
for k=1:0.5:slice
    for i=start:end_time
        img(td_data.y(i)+1,td_data.x(i)+1,k) = td_data.p(i);
    end
    interm=start;
    start=end_time+1;
    k
    if end_time+frame_time<t_end
        end_time = find(td_data.ts>=td_data.ts(interm)+frame_time,1);
    else
        break;
    end
end

%%%%%% Image Display
img=img+ones(sy,sx,slice);   
displayIm3d(img, [0 2])

end

