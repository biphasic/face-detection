figure 
maximumDifference = 50000;
for s = 1:length(subjects)
    %ax = subplot(3,3*numberOfSubjects,[16+3*s 16+3*s+1 16+3*s+2]);
    for r = 1:numel(subjects(s).Recordings)
        ax = subplot(length(subjects),length(subjects(1).Recordings),(s-1)*3 + r);
    %for r = 1:numel(subjects(s).Recordings)
    %    if ~isempty(subjects(s).Recordings{r}) && subjects(s).Recordings{r}.IsTrainingRecording
    %        break
    %    end
    %end
        grid1 = subjects(s).Recordings{r}.EventstreamGrid1;
        corrThreshold = subjects(s).CorrelationThreshold;
        scatter3(grid1.x(grid1.patternCorrelation>corrThreshold), -grid1.ts(grid1.patternCorrelation>corrThreshold), grid1.y(grid1.patternCorrelation>corrThreshold))
        hold on
        title(ax, subjects(s).Name);

        grid2 = subjects(s).Recordings{r}.EventstreamGrid2;
        scatter3(grid2.x(grid2.patternCorrelation>corrThreshold), -grid2.ts(grid2.patternCorrelation>corrThreshold), grid2.y(grid2.patternCorrelation>corrThreshold))
        set(gca, 'xtick', [0:19:304])
        set(gca, 'ztick', [0:15:240])
        zlim([0 240])
        xlim([0 304])

        %for e = grid1.ts(grid1.patternCorrelation>corrThreshold)
        maximumDifference = 50000;
        valid = grid1.ts(grid1.patternCorrelation>corrThreshold);
        for e = 2:length(valid)
            %x = abs(grid1.x(grid1.ts == valid(e)) - grid1.x(grid1.ts == valid(e-1)) )/2;
            x1 = grid1.x(grid1.ts == valid(e));
            x2 = grid1.x(grid1.ts == valid(e-1));
            x = (x1(1) + x2(1))/2;
            y = grid1.y(grid1.ts == valid(e));
            y = y(1);
            if (valid(e) - valid(e-1)) < maximumDifference && isequal(grid1.y(grid1.ts == valid(e)), grid1.y(grid1.ts == valid(e-1))) && abs(x1(1) - x2(1)) < 60
                scatter3(ax, x, -valid(e), y, 'red', 'diamond', 'filled')
            end
        end

        valid = grid2.ts(grid2.patternCorrelation>corrThreshold);
        for e = 2:length(valid)
            %x = abs(grid2.x(grid2.ts == valid(e)) - grid2.x(grid2.ts == valid(e-1)) )/2;
            x1 = grid2.x(grid2.ts == valid(e));
            x2 = grid2.x(grid2.ts == valid(e-1));
            x = (x1(1) + x2(1))/2;
            y = grid2.y(grid2.ts == valid(e));
            y = y(1);
            if (valid(e) - valid(e-1)) < maximumDifference && isequal(grid2.y(grid2.ts == valid(e)), grid2.y(grid2.ts == valid(e-1))) && abs(x1(1) - x2(1)) < 60
                scatter3(ax, x, -valid(e), y, 'red', 'diamond', 'filled')
            end
        end
    end
end