tic
for s = 1:length(outdoorSubjects)
    for r = 1:numel(outdoorSubjects(s).Recordings)
        if ~isempty(outdoorSubjects(s).Recordings{r})
            disp(['Subject: ', outdoorSubjects(s).Name, ', recording no: ', num2str(r)])
            outdoorSubjects(s).Recordings{r}.calculatecorrelation(outdoorSubjects(s).AmplitudeScale, outdoorSubjects(s).BlinkLength, outdoorSubjects(s).Modelblink);
        end
    end
end
toc