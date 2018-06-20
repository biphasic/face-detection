rec = events;

camera_width = 304;
camera_height = 240;
gridScale = 16;
tile_width = camera_width/gridScale;
tile_height = camera_height/gridScale;

%tic
%tile1 = crop_spatial(rec, 142, 123, tile_width, tile_height);c{4,9}.
%tile1 = activity(tile1, 50000, true);
%%tile1 = quick_correlation(tile1, 60);
%toc

c = cell(gridScale);

tic
for i = 1:gridScale
    for j = 1:gridScale
        tile = crop_spatial(rec, (i-1) * tile_width, (j-1) * tile_height, tile_width, tile_height);
        tile = activity(tile, 50000, true);
        tile = quick_correlation(tile, 60);
        c{i,j} = tile;
    end
    i
end

%a = cellfun(@quick_correlation, c, amplitudeScale);
toc