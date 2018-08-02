rec = events;

camera_width = 304;
camera_height = 240;
gridScale = 16;
tile_width = camera_width/gridScale;
tile_height = camera_height/gridScale;
c = cell(gridScale);
c2 = cell(gridScale - 1);

tic
for i = 1:gridScale
    for j = 1:gridScale
        tile = crop_spatial(rec, (i-1) * tile_width, (j-1) * tile_height, tile_width, tile_height);
        tile = activity(tile, 50000, true);
        tile = quick_correlation(tile, amplitudeScale);
        c{i,j} = tile;
    end
    i
end

for i = 1:gridScale
    for j = 1:gridScale
        tile = crop_spatial(rec, (i-1) * tile_width + floor(tile_width/2), (j-1) * tile_height + floor(tile_height/2), tile_width, tile_height);
        tile = activity(tile, 50000, true);
        tile = quick_correlation(tile, amplitudeScale);
        c2{i,j} = tile;
    end
    i
end

%a = cellfun(@quick_correlation, c);
toc