error = 1;

count = 0;
for sigmaX = 3:1:13
    for posInertia = 0.9:0.01:0.99
        for minProb = 0.001:0.002:0.02
            count = count + 1;
            outdoor.ricardo.Recordings{1}.calculatetracking(sigmaX, round(sigmaX * 2/3), posInertia, minProb);
            outdoor.ricardo.Recordings{1}.calculatetrackingerrorViolaJones;
            if outdoor.ricardo.Recordings{1}.AverageTrackingError < error
                error = outdoor.ricardo.Recordings{1}.AverageTrackingError;
                disp(['Error: ', num2str(error), ', SigmaX: ', num2str(sigmaX), ', positionInertia: ', num2str(posInertia), ', min Probability: ', num2str(minProb)])
            end
        end
    end
end

format shortg
c = clock