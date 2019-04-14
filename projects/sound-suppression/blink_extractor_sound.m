if ~exist('soundsuppressionrecording', 'var')
    disp('loading compressed recording from file...')
    load('soundsuppressionrecording-cut-10000.mat')
end

%%
soundsuppression = Collection('soundsuppression');
subject = Subject('tests', 0.88, soundsuppression);
subject.addrecording(2, soundsuppressionrecording, true);
subject.Recordings{2}.Center.Location = [130 410];
subject.Recordings{2}.Center.Times = [4570000];
subject.ActivityDecayConstant = activityConstant;
%subject.BlinkLength = 250000;
subject.Recordings{2}.Dimensions = [640 480];
%subject.Recordings{2}.GridSizes = [1 1];
subject.Modelblink = subject.Recordings{2}.getmodelblink(30);

addprop(soundsuppression, subject.Name);
soundsuppression.('tests') = subject;
soundsuppression.tests.plotmodelblinkwithallblinks