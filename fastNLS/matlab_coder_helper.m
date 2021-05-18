%% Matlab coder helper
input = 1-2*rand(512,1);
[p,o] = setupFastNLS(numel(input), 20, [100, 2000], 44100, input);
