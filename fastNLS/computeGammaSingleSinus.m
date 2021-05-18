%% computeGammaSingleSinus
% FastNLS simplified implementation for MATLAB coder - by Søren Vøgg Lyster

function [psi, phi, gamma] = computeGammaSingleSinus(...
    crossCorrelationVectors, a, hankelMatrixIsAdded)
    R = computeRowsOfToeplitzHankelMatrix(1,1,...
        crossCorrelationVectors, hankelMatrixIsAdded);
    psi = 1./R(1,:);
    gamma = psi;
    phi = a.*gamma;
end