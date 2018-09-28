function [checkerboard] = GenerateCheckerboardTexture(screenDim,numSquares)
% Generates 2 alternating checkerboards: checkerboard{1} and checkerboard{2}
% screenDim = [width height];  
% Written by RA 03-21-2017 (adapted from Kevin alternatingCheckerboards)
    checkerboard = cell(1,2);
    for i = 1:2
        screenRatio = ceil(max(screenDim)/min(screenDim)); %ratio for adjusting the texture, so that the squares are still squares when they fill the screen
        if mod(numSquares, 2) == 0
            checkerboard{i} = repmat(eye(2), (numSquares/2), numSquares/2 * screenRatio); %creating the matrix for the texture for even squares
        elseif mod(numSquares, 2) == 1
            checkerboard{i} = repmat(eye(2), ceil(numSquares/2), ceil(numSquares/2 * screenRatio)); %creating the matrix for the texture for odd squares
            checkerboard{i} = checkerboard{i}(1:end-1, 1:end-1);
        else
            disp('Error in number of squares, check the parameters')
        end
        if i == 2
            checkerboard{i} = checkerboard{i}*-1 + 1; %inverts the matrix for the second checkerboard, so we have the inverted checkerboard
        end
    end