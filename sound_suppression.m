close all;
audiopath = '/home/gregorlenz/Recordings/sound-suppression/patent-application/';
clean_rec_file = 'denoised-rec.m4a';
noisy_rec_file = 'totally-noisy-rec.m4a';
clean_rec = [audiopath, clean_rec_file];
noisy_rec = [audiopath, noisy_rec_file];

info_clean = audioinfo(clean_rec);
[y_clean, Fs] = audioread(clean_rec);
limit = 65000;

scaleNumber = 1;
coeff = ones(1, scaleNumber)/scaleNumber;
avgSignal = 1.5*filter(coeff, 1, y_clean);

t_clean = 0:seconds(1/Fs):seconds(info_clean.Duration);
t_clean = t_clean(1:end-1);
subplot(3, 1, 3);
plot(t_clean(1:end-limit),avgSignal(1:end-limit,1))
xlabel('Time')
ylabel('clean audio')

subplot(3, 1, 2);
info_noisy = audioinfo(noisy_rec);
[y_noisey, Fs] = audioread(noisy_rec);

t_noisy = 0:seconds(1/Fs):seconds(info_noisy.Duration);
t_noisy = t_noisy(1:end-1);
y_noisey(1:2*limit,1) = y_noisey(1:2*limit,1) - (1.5*y_clean(end-(2*limit-1):end,1));
plot(t_noisy(1:end-limit),y_noisey(1:end-limit,1))
hold on 
plot(t_noisy(1:end-limit),y_noisey(1:end-limit,1))

xticklabels('')
ylabel('noisy audio')

[up, low] = envelope(y_clean, 500, 'peak');
subplot(3, 1, 1);
plot(t_clean(1:end-limit),up((1:end-limit),1), 'linewidth',1.5,  'color', 'black')
hold on;
plot(t_clean(1:end-limit),low((1:end-limit),1), 'linewidth',1.5, 'color', 'black')
%plot(t_clean,up(:,1),t_clean,low(:,1),'linewidth',1.5)
xticklabels('')
ylabel('visual input')
