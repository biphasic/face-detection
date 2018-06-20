hold on

for i = 1:16
    for j = 1:16
        scatter3(c{i,j}.x(c{i,j}.patternCorrelation>0.88), c{i,j}.patternCorrelation(c{i,j}.patternCorrelation>0.88), c{i,j}.y(c{i,j}.patternCorrelation>0.88));
    end
end