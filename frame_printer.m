clf
firstframe = 5;
lastframe = 13;
for i = firstframe:2:lastframe
    if i < 10
        framepath = (['/home/gregorlenz/Vidéos/medium-visualisation/frames/frame000', num2str(i), '.jpg']);
    elseif i < 100
        framepath = (['/home/gregorlenz/Vidéos/medium-visualisation/frames/frame00', num2str(i), '.jpg']);
    end
    if exist(framepath, 'file') == 2
        img = imread(framepath);
        %img = double(img)/255;
        %index1 = img(:,:,1) == 1;
        %index2 = img(:,:,2) == 1;
        %index3 = img(:,:,3) == 1;
        %indexWhite = index1+index2+index3==3;
        %for idx = 1 : 3
        %   rgb = img(:,:,idx);     % extract part of the image
        %   rgb(indexWhite) = NaN;  % set the white portion of the image to NaN
        %   img(:,:,idx) = rgb;     % substitute the update values
        %end
        X = [0 size(img, 2); 0 size(img,2)];
        deltaT = 100;
        Y = ([i * deltaT, i * deltaT; i * deltaT, i * deltaT] - firstframe*deltaT);
        Z = [size(img, 1) size(img, 1); 0 0];
        axis('tight')
        ylim([0 (lastframe - firstframe)*deltaT])
        set(gca, 'xticklabels', {})
        set(gca, 'xtick', [])
        set(gca, 'yticklabels', {})
        set(gca, 'ytick', [])
        set(gca, 'zticklabels', {})
        set(gca, 'ztick', [])
        view([144, 16.6])
        set(gca,'linewidth',3)
        surface(X, Y, Z, img,'FaceColor','texturemap', 'EdgeColor', 'none')%,'FaceAlpha', 0.7); 
    end
end