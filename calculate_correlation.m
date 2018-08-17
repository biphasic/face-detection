tic
for s = 1:length(subjects)
    for r = 1:numel(subjects(s).Recordings)
        if ~isempty(subjects(s).Recordings{r}) && subjects(s).Recordings{r}.IsTrainingRecording
            disp(['Subject: ', subjects(s).Name, ', recording no: ', num2str(r)])
            subjects(s).Recordings{r}.calculatecorrelation(300000);
        end
    end
end
toc