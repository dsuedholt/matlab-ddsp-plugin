%% computeGammaTwoSinus
% FastNLS simplified implementation for MATLAB coder - by Søren Vøgg Lyster

function [R, alpha, gamma] = computeGammaTwoSinus(...
    crossCorrelationVectors, psi, gamma, hankelMatrixIsAdded)
    nPitches = length(psi);
    R = computeRowsOfToeplitzHankelMatrix(2, 2,...
        crossCorrelationVectors, hankelMatrixIsAdded);
    alpha = R(1,:).*gamma;
    gamma = [-R(1,:).*psi;ones(1,nPitches)]./(ones(2,1)*...
        (R(2,:)-R(1,:).^2.*psi));
end