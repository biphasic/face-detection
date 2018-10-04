subjects = outdoorSubjects;
tic
for s = 1:length(subjects)
    for r = 1:numel(subjects(s).Recordings)
        if ~isempty(subjects(s).Recordings{r})
            disp(['Subject: ', subjects(s).Name, ', recording no: ', num2str(r)])
            subjects(s).Recordings{r}.calculatecorrelation();
        end
    end
end
toc