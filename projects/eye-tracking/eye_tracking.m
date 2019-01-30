if ~exist('eyerecording', 'var')
    disp('loading compressed recording from file...')
    load('eyerecording-500.mat')
end

%%
eyerecording = activity(eyerecording, 50000);

skip = 100;
scatter(eyerecording.ts(1:skip:end), eyerecording.activityOn(1:skip:end))
hold on
scatter(eyerecording.ts(1:skip:end), eyerecording.activityOff(1:skip:end))

%%
collection = Collection('eyes');
subject = Subject('gregor', 0.88, collection);
subject.addrecording(1, eyerecording, true);
subject.Recordings{1}.Center.Location = [320 240];
subject.Recordings{1}.Center.Times = [418900 1180000 6350000];
subject.BlinkLength = 250000;
subject.Recordings{1}.Dimensions = [640 480];
subject.Recordings{1}.GridSizes = [1 1];
subject.Modelblink = subject.Recordings{1}.getmodelblink(30);
