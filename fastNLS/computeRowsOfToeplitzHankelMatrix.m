%% computeRowsOfToeplitzHankelMatrix
% FastNLS simplified implementation for MATLAB coder - by Søren Vøgg Lyster

function rowMatrix = computeRowsOfToeplitzHankelMatrix(rowNumber,...
        nColumns, crossCorrelationVectors, hankelMatrixIsAdded)
    if rowNumber == 1
        toeplitzRows = crossCorrelationVectors(1:nColumns,:);
    else
        toeplitzRows = ...
            [flip(crossCorrelationVectors(2:rowNumber,:),1);...
            crossCorrelationVectors(1:nColumns-rowNumber+1,:)];
    end
    hankelOffset = 3;
    hankelRows = crossCorrelationVectors((0:nColumns-1)+...
                                         hankelOffset+rowNumber-1,:);
    if hankelMatrixIsAdded
        rowMatrix = toeplitzRows + hankelRows;
    else
        rowMatrix = toeplitzRows - hankelRows;
    end
end