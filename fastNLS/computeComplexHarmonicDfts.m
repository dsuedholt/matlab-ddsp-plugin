%% computeComplexHarmonicDfts
% FastNLS simplified implementation for MATLAB coder - by Søren Vøgg Lyster

function [harmonicDfts, pitchGrids] = ...
        computeComplexHarmonicDfts(dataVector, fullPitchGrid, ...
        pitchOrder, fftShiftVector)
    nDft = round(1/diff(fullPitchGrid(1:2)));
    dftData = fft(dataVector, nDft);
    pitchBounds = fullPitchGrid([1,end]);
    fftShiftVectorLength = length(fftShiftVector);
    shiftedDftData = (dftData(1:fftShiftVectorLength).*fftShiftVector).';
    tmpHarmonicDfts = complex(pitchOrder, nDft);
    tmpPitchGrids = nan(pitchOrder, nDft); 
    nPitches = 0;
    for ii = 1:pitchOrder
        dftIndices = computeDftIndicesNHarmonic(nDft, pitchBounds, ii);
        nPitches = length(dftIndices);
        if ii == 1
            tmpPitchGrids = nan(pitchOrder, nPitches);
            tmpHarmonicDfts = nan(pitchOrder, nPitches);
        end
        tmpPitchGrids(ii,1:nPitches) = fullPitchGrid(1:nPitches);
        tmpHarmonicDfts(ii, 1:nPitches) = shiftedDftData(dftIndices+1);
    end
    pitchGrids = tmpPitchGrids(:,:);
    harmonicDfts = tmpHarmonicDfts(:,:);
end

function dftIndices = computeDftIndicesNHarmonic(nDft, pitchBounds, ...
        pitchOrder)
    minPitchIdx = max(0, round(pitchBounds(1)*nDft));
    maxPitchIdx = min(nDft/(2*pitchOrder)-1, ...
        round(pitchBounds(2)*nDft));
    dftIndices = (minPitchIdx:maxPitchIdx)*pitchOrder;
end
