if ~exist('eyerecording', 'var')
    disp('loading compressed recording from file...')
    load('eyerecording-10.mat')
end

%%
activityConstant = 20000;
eyerecording = activity(eyerecording, 20000);

%%
skip = 100;
scatter(eyerecording.ts(1:skip:end), eyerecording.activityOn(1:skip:end))
hold on
scatter(eyerecording.ts(1:skip:end), eyerecording.activityOff(1:skip:end))

%%
collection = Collection('eyes');
subject = Subject('gregor', 0.88, collection);
subject.addrecording(1, eyerecording, true);
subject.Recordings{1}.Center.Location = [320 240];
subject.Recordings{1}.Center.Times = [428900     1185860    10655740];%6369980
subject.ActivityDecayConstant = activityConstant;
subject.BlinkLength = 100000;
subject.Recordings{1}.Dimensions = [640 480];
subject.Recordings{1}.GridSizes = [1 1];
subject.Modelblink = subject.Recordings{1}.getmodelblink(30);
