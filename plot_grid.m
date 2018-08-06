figure 
for s = 1:numberOfSubjects
    %ax = subplot(3,3*numberOfSubjects,[16+3*s 16+3*s+1 16+3*s+2]);
    ax = subplot(1,numberOfSubjects,s);
    %ax = subplot(1,1,s);
    %delete(ax);
    print1 = 1;
    if print1
        for j = 1:gridScale
            for i = 1:gridScale
                ts = subjects{2,s+1}{i,j}.ts(subjects{2,s+1}{i,j}.patternCorrelation>subjects{4,s+1});
                if numel(ts) > 0
                    x = ones(1,numel(ts)).*((i-1) * tile_width + floor(tile_width/2));
                    y = ones(1,numel(ts)).*((j-1) * tile_height + floor(tile_height/2));
                    %normalised x and y according to tile
                    scatter3(ax, x, y, ts, 'b', 'filled');
                    hold on;
                    %x and y of last event that triggered correlation
                    %scatter3(c{i,j}.x(c{i,j}.patternCorrelation>correlationThreshold), c{i,j}.y(c{i,j}.patternCorrelation>correlationThreshold), c{i,j}.ts(c{i,j}.patternCorrelation>correlationThreshold), 'filled');
                hold on
                end
            end
        end
    end

    print2 = 1;
    if print2
        for j = 1:(gridScale-1)
            for i = 1:(gridScale-1)
                ts = subjects{3,s+1}{i,j}.ts(subjects{3,s+1}{i,j}.patternCorrelation>subjects{4,s+1});
                if numel(ts) > 0
                    x = ones(1,numel(ts)).*(i * tile_width);
                    y = ones(1,numel(ts)).*(j * tile_height);
                    scatter3(ax, x, y, ts, 'g', 'filled')
                    %scatter3(c2{i,j}.x(c2{i,j}.patternCorrelation>correlationThreshold), c2{i,j}.y(c2{i,j}.patternCorrelation>correlationThreshold), c2{i,j}.ts(c2{i,j}.patternCorrelation>correlationThreshold), 'filled');
                hold on
                end
            end
        end
    end
    set(gca, 'xtick', [0:19:304])
    set(gca, 'ytick', [0:15:240])
    axis([0 340 0 240])
end
plot_constraints