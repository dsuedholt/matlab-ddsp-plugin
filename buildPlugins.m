% helper script to build plugins for each weight file
addpath('plugincode');


if ~isfile('violinWeights.mat')
    disp('Downloading violin weight file...');
    websave('violinWeights.mat', 'https://github.com/dsuedholt/matlab-ddsp-plugin/raw/0.1.0/violinWeights.mat');
    disp('Done');
end
validateAudioPlugin violinPlugin;
generateAudioPlugin violinPlugin;

if ~isfile('saxophoneWeights.mat')
    disp('Downloading saxophone weight file...');
    websave('saxophoneWeights.mat', 'https://github.com/dsuedholt/matlab-ddsp-plugin/raw/0.1.0/saxophoneWeights.mat');
    disp('Done');
end
validateAudioPlugin saxophonePlugin;
generateAudioPlugin saxophonePlugin;

if ~isfile('fluteWeights.mat')
    disp('Downloading flute weight file...');
    websave('fluteWeights.mat', 'https://github.com/dsuedholt/matlab-ddsp-plugin/raw/0.1.0/fluteWeights.mat');
    disp('Done');
end
validateAudioPlugin flutePlugin;
generateAudioPlugin flutePlugin;

if ~isfile('trumpetWeights.mat')
    disp('Downloading trumpet weight file...');
    websave('trumpetWeights.mat', 'https://github.com/dsuedholt/matlab-ddsp-plugin/raw/0.1.0/trumpetWeights.mat');
    disp('Done');
end
validateAudioPlugin trumpetPlugin;
generateAudioPlugin trumpetPlugin;