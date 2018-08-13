function [results] = simu_events_filter_x(file,alpha_up, alpha_down, t_start,t_end)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Filtrer le bruit en fonction de la difference de flux avec l'Evenement
% % precedent (mal dit...)
% 
% 
% APS = load_atis_aps(filename);
% 
% n = size(APS.gray,2);
% 
% for i=1:(n-1)
%     APS.gray
%     
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

APS = load_atis_aps(file);

I=APS.x;
J=APS.y;
tps=APS.ts; % *10^-6
ndg=APS.gray;

if nargin <=4
    t_start=1;
    t_end=length(tps);
end

if nargin <=2
    alpha_up=2;%0.2
    alpha_down=1.2;%0.03
end

clear TD;

Img=zeros(max(I)+1,max(J)+1);

results.x=[];
results.y=[];
results.ts=[];
results.p=[];

for inc=t_start:t_end,

   x=I(inc)+1;
   y=J(inc)+1;
   ts=tps(inc);
   gray=ndg(inc);

   if gray > (1+alpha_up) * Img(x,y),
   %if (gray-Img(x,y)) > k 
    results.x=[results.x x];
    results.y=[results.y y];
    results.ts=[results.ts ts];
    results.p=[results.p 1];
    Img(x,y)=gray;
   
   elseif gray < (1-alpha_down) * Img(x,y),
   %elseif (gray-Img(x,y)) < k
    results.x=[results.x x];
    results.y=[results.y y];
    results.ts=[results.ts ts];
    results.p=[results.p -1];
    Img(x,y)=gray;
   end

   inc
   
end

name_file=['simu_dvs_',num2str(alpha_up),'_pipo.mat'];

%name_file=['simu_dvs_',num2str(k),'_pipo.mat'];

save(name_file,'results');
end
