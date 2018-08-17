%data = load_eventstream('face0_td.es', false, true);
data = events;

figure()

dt = 5e3;
last_ts = 0;
img = zeros(304,240)';
imagesc(img)
hold on

ymax = 240; %depending on the camera

for i = 1:length(data.ts)
    img(ymax-data.y(i)+1,data.x(i)+1,:) = data.p(i);
    %line(50,50,:);
    if( data.ts(i) - last_ts > dt)
       last_ts = data.ts(i);
       imagesc(img);
       drawnow;
       img = zeros(304,240)';
    end
end