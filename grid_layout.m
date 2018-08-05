rec = events;

grids = cell(2,3);
tic
for s = 1:numberOfSubjects
    if s == 1
        rec = eventsFede;
        disp('fede')
    elseif s == 2 
        rec = eventsAlex;        
        disp('alex')
    elseif s == 3
        rec = eventsLaure;
        disp('laure')
    end
    filterOn = filters{1, s};
    filterOff = filters{2, s};
    
    camera_width = 304;
    camera_height = 240;
    gridScale = 16;
    tile_width = camera_width/gridScale;
    tile_height = camera_height/gridScale;
    c = cell(gridScale);
    c2 = cell(gridScale - 1);
    
    disp('grid 1')
    for i = 1:gridScale
        for j = 1:gridScale
            tile = crop_spatial(rec, (i-1) * tile_width, (j-1) * tile_height, tile_width, tile_height);
            tile = activity(tile, 50000, true);
            tile = quick_correlation(tile, filterOn, filterOff, amplitudeScale);
            c{i,j} = tile;
        end
    end

    disp('grid 2')
    for i = 1:gridScale
        for j = 1:gridScale
            tile = crop_spatial(rec, (i-1) * tile_width + floor(tile_width/2), (j-1) * tile_height + floor(tile_height/2), tile_width, tile_height);
            tile = activity(tile, 50000, true);
            tile = quick_correlation(tile, filterOn, filterOff, amplitudeScale);
            c2{i,j} = tile;
        end
    end
    grids{1,s} = c;
    grids{2,s} = c2;
end
toc
    