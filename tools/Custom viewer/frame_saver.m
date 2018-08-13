%% Enregistrement images depuis un stack

for i=1:876
    imshow(img(:,:,i),[0 2])
    colormap gray
    fname=sprintf('img%03d.png',i);
    screen2png(fname)
end