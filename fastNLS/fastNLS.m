%% FastNLS simplified implementation for MATLAB coder - by Søren Vøgg Lyster

classdef fastNLS < handle
    properties (Access=private)
        N
        L
        F
        Gamma1
        Gamma2
        pitchBoundsOuter = [0.0, 0.5]
        epsilon = 0.0
        epsilon_ref = 0.0
        crossCorrelationVectors
        fftShiftVector
        pitchBounds
        fullPitchGrid
        validFftIndices
        defaultRefinementTol
        refinementTol
        gPriorParam = 3
        logPitchPdfs
        logModelPmf
        dataPowerRegParam = 5e-3;
        estPitch
        estOrder
    end
    methods
        function obj = fastNLS(N,L,pitchBounds)
            obj.reset(N, L, pitchBounds);
        end
        
        function reset(obj, N, L, pitchBounds)
            obj.pitchBounds = pitchBounds;
            obj.F = 5*N*L;
            obj.L = L;
            obj.N = N;
            minFftIndex = ceil(obj.F*pitchBounds(1));
            maxFftIndex = floor(obj.F*pitchBounds(2));
            obj.validFftIndices = (minFftIndex:maxFftIndex)';
            obj.fullPitchGrid = obj.validFftIndices/obj.F;
            nPitches = length(obj.fullPitchGrid);
            obj.crossCorrelationVectors = ...
               [N*ones(1, nPitches)/2 + N*obj.epsilon;...
               sin(pi*(1:2*L)'*obj.fullPitchGrid'*N)./...
               (2*sin(pi*(1:2*L)'*obj.fullPitchGrid'))];
            obj.fftShiftVector = ...
               exp(1i*2*pi*(0:ceil(obj.F/2)-1)'*(N-1)/(2*obj.F));
            [obj.Gamma1, obj.Gamma2] = computeGamma(L, obj.F, pitchBounds,...
               obj.crossCorrelationVectors, nPitches,...
               obj.validFftIndices);
        end
        
        function [costFunctions] = computeCostFunctions(obj, x)
            coder.varsize('x');
            costFunctions = computeAllCostFunctions(x,obj.L,...
                obj.fullPitchGrid, obj.fftShiftVector,...
                obj.crossCorrelationVectors, obj.Gamma1, obj.Gamma2);
        end 
        
        function [estimatedPitch, estimatedOrder] = estimate(obj, x)
            coder.varsize('x');
            if x'*x < 1e-14
                estimatedPitch = nan;
                estimatedOrder = 0;
            else
                pitchLogPrior = -log(diff(obj.pitchBounds));
                logModelPrior = log(1/(obj.L+1));
                costs = obj.computeCostFunctions(x);
                cod = costs*(1/(x'*x+obj.dataPowerRegParam));
                [~, pitchLogLikelihood] = ...
                    computePitchLogLikelihood(cod, obj.N, obj.gPriorParam);
                scaledPitchLogPosterior = ...
                    pitchLogLikelihood + pitchLogPrior;
                logMarginalLikelihood = computeLogMarginalLikelihood(...
                    scaledPitchLogPosterior, obj.fullPitchGrid);
                obj.logPitchPdfs = scaledPitchLogPosterior-...
                    logMarginalLikelihood'*...
                    ones(1,size(scaledPitchLogPosterior,2));
                logMarginalLikelihood = [0, logMarginalLikelihood];
                postModelPmf = computePostModelPmf(...
                    logMarginalLikelihood, logModelPrior);
                obj.logModelPmf = log(postModelPmf);
                [~, estimatedOrderIdx] = max(postModelPmf);
                estimatedOrder = estimatedOrderIdx-1;
                if estimatedOrder > 0
                    [~, pitchIndex] = ...
                        max(scaledPitchLogPosterior(estimatedOrder, :));
                    estimatedPitch = obj.fullPitchGrid(pitchIndex(1));
                else 
                    estimatedPitch = nan;
                end
            end
        end
    end
end