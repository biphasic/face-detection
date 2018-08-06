%correlationThreshold = 0.80;
maxDiff = 50000;

for s = 1:numberOfSubjects
    %ax = subplot(3,3*numberOfSubjects,[16+3*s 16+3*s+1 16+3*s+2]);
    ax = subplot(1,numberOfSubjects,s);
    hold on
    %for each cell
    [n, m] = size(c);
    for i = 1:n
        for j = 1:m
            %for each valid event in cell
            if print1
                for ts = subjects{2,s+1}{i, j}.ts(subjects{2,s+1}{i,j}.patternCorrelation>subjects{4,s+1})
                    if i < n
                        for a = subjects{2,s+1}{i+1, j}.ts(subjects{2,s+1}{i+1,j}.patternCorrelation>subjects{4,s+1})
                            if ts < a && (a - maxDiff) < ts
                                t = ts + floor((ts - a)/2)
                                scatter3(i*tile_width, j*tile_height-tile_height/2, t, 'red', 'diamond', 'filled')
                            end
                        end
                    end
                    if i > 1
                        for a = subjects{2,s+1}{i-1, j}.ts(subjects{2,s+1}{i-1,j}.patternCorrelation>subjects{4,s+1})
                            if ts < a && (a - maxDiff) < ts
                                t = ts + floor((ts - a)/2)
                                scatter3((i-1)*tile_width, j*tile_height-tile_height/2, t, 'red', 'diamond', 'filled')
                            end
                        end
                    end
                end
            end
            if print2
                for ts = subjects{3,s+1}{i, j}.ts(subjects{3,s+1}{i,j}.patternCorrelation>correlationThreshold)
                    if i < n
                        for a = subjects{3,s+1}{i+1, j}.ts(subjects{3,s+1}{i+1,j}.patternCorrelation>subjects{4,s+1})
                            if ts < a && (a - maxDiff) < ts
                                t = ts + floor((ts - a)/2)
                                scatter3(i*tile_width + tile_width/2, j*tile_height, t, 'red', 'diamond', 'filled')
                            end
                        end
                    end
                    if i > 1
                        for a = subjects{3,s+1}{i-1, j}.ts(subjects{3,s+1}{i-1,j}.patternCorrelation>subjects{4,s+1})
                            if ts < a && (a - maxDiff) < ts
                                t = ts + floor((ts - a)/2)
                                scatter3((i-1)*tile_width + tile_width/2, j*tile_height, t, 'red', 'diamond', 'filled')
                            end
                        end
                    end
                end
            end
            %disp('next')
        end
    end
end