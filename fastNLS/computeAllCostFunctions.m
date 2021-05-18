%% computeAllCostFunctions
% FastNLS simplified implementation for MATLAB coder - by Søren Vøgg Lyster

function costFunctions = computeAllCostFunctions(x, L, fullPitchGrid,...
    fftShiftVector, crossCorrelationVectors, Gamma1, Gamma2)
    [harmonicDfts, pitchGrids] = computeComplexHarmonicDfts(x,...
        fullPitchGrid, L, fftShiftVector);
    nPitches = length(fullPitchGrid);
    costFunctions = nan(L, nPitches);
    lsSol1 = nan(L,nPitches);
    lsSol2 = nan(L,nPitches);
    coder.varsize('lsSol1', 'lsSol2');
    for l = 1:L
        nPitches = sum(~isnan(pitchGrids(l,:)));
        gamma1 = Gamma1{l};
        gamma2 = Gamma2{l};
        if l == 1
            lsSol1 = real(harmonicDfts(l,1:nPitches)).*gamma1; 
            lsSol2 = imag(harmonicDfts(l,1:nPitches)).*gamma2;
        else
            ll = l;
            R1 = computeRowsOfToeplitzHankelMatrix(ll, ll, ...
                crossCorrelationVectors(1:2*l+1, 1:nPitches), true);
            lambda1 = (ones(ll, 1)*(real(harmonicDfts(l,1:nPitches))-...
                sum(R1(1:end-1,:).*lsSol1(1:l-1, 1:nPitches),1)));
            lsSol1 = [lsSol1(1:l-1, 1:nPitches); zeros(1, nPitches)] ...
                + lambda1.*gamma1;
            R2 = computeRowsOfToeplitzHankelMatrix(l, l, ...
                crossCorrelationVectors(1:2*l+1, 1:nPitches), false);
            lambda2 = (ones(l, 1)*(imag(harmonicDfts(l,1:nPitches))-...
                sum(R2(1:end-1, :).*lsSol2(1:l-1, 1:nPitches),1)));
            lsSol2 = [lsSol2(1:l-1, 1:nPitches); zeros(1, nPitches)] ...
                 + lambda2.*gamma2;
        end
        costFunctions(l, 1:nPitches) = ...
            sum(real(harmonicDfts(1:l,1:nPitches)).*lsSol1(1:l,:),1)+...
            sum(imag(harmonicDfts(1:l,1:nPitches)).*lsSol2(1:l,:),1);
    end