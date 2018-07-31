correlationThreshold = 0.9;
print1 = 1
if print1
    for j = 1:gridScale
        for i = 1:gridScale
            ts = c{i,j}.ts(c{i,j}.patternCorrelation>correlationThreshold);
            if numel(ts) > 0
                x = ones(1,numel(ts)).*((i-1) * tile_width + floor(tile_width/2));
                y = ones(1,numel(ts)).*((j-1) * tile_height + floor(tile_height/2));
                %normalised x and y according to tile
                scatter3(x, y, ts, 'filled');
                %x and y of last event that triggered correlation
                %scatter3(c{i,j}.x(c{i,j}.patternCorrelation>correlationThreshold), c{i,j}.y(c{i,j}.patternCorrelation>correlationThreshold), c{i,j}.ts(c{i,j}.patternCorrelation>correlationThreshold), 'filled');
            hold on
            end
        end
    end
end

print2 = 1
if print2
    for j = 1:(gridScale-1)
        for i = 1:(gridScale-1)
            ts = c2{i,j}.ts(c2{i,j}.patternCorrelation>correlationThreshold);
            if numel(ts) > 0
                x = ones(1,numel(ts)).*(i * tile_width);
                y = ones(1,numel(ts)).*(j * tile_height);
                scatter3(x, y, ts, 'filled')
                %scatter3(c2{i,j}.x(c2{i,j}.patternCorrelation>correlationThreshold), c2{i,j}.y(c2{i,j}.patternCorrelation>correlationThreshold), c2{i,j}.ts(c2{i,j}.patternCorrelation>correlationThreshold), 'filled');
            hold on
            end
        end
    end
end