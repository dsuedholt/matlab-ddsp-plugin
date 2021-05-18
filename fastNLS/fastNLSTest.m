%% fastNLS test 

[a, fs] = audioread("vocal.wav");

maxOrder = 20;
minF0 = 100;
maxF0 = 1000;
pitchBounds = [minF0, maxF0];
sLength = round(0.025*fs);
sTime = sLength/fs;
sNr = floor(size(a,1)/sLength);

pitchEstimator = fastNLS(sLength, maxOrder, pitchBounds/fs);
pitchTrack = nan(sNr,1);
orderTrack = nan(sNr,1);

idx = 1:sLength;
for n = 1:sNr
   data = a(idx);
   [pitchTrack(n), orderTrack(n)] = pitchEstimator.estimate(data);
   idx = idx + sLength;
end

pitchTrack = pitchTrack * fs;

segmentLength = round(sTime*fs);
specSLength = round(2*sLength);
specWindow = gausswin(specSLength);
nDft = 4096;
specNOverlap = round(3*specSLength/4);
[S, F, T] = spectrogram(a(:,1), specWindow, specNOverlap, nDft, fs);

timeVector = sTime/2+(1:sNr)*sTime-sTime/2;

figure(1)
imagesc(T,F,20*log10(abs(S)))
set(gca,'YDir','normal')
hold on
plot(timeVector, pitchTrack,'r.')
ylim([0,1000])
hold off
xlabel('time [s]')
ylabel('frequency [Hz]')