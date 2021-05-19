function out = buildPlugin
    net = coder.loadDeepLearningNetwork('violin.mat');
    out = predict(net, 1, 1);
end