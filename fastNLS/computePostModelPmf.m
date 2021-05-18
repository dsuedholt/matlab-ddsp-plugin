%% computePostModelPmf
% FastNLS simplified implementation for MATLAB coder - by Søren Vøgg Lyster

function postModelPmf = computePostModelPmf(logMarginalLikelihood, ...
        logModelPrior)
    scaledLogPostModelPmf = logMarginalLikelihood + logModelPrior;
    scaledPostModelPmf = ...
        exp(scaledLogPostModelPmf-max(scaledLogPostModelPmf));
    postModelPmf = scaledPostModelPmf/sum(scaledPostModelPmf);
end
