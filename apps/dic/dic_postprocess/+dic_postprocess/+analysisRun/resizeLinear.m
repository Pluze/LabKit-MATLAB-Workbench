% DIC Postprocess ops helper. Expected caller: app-owned overlay helpers.
% Inputs are a 2-D numeric map and target [rows cols]. Output is linearly
% interpolated data without requiring Image Processing Toolbox. Side effects:
% none.
function imageOut = resizeLinear(imageIn, targetSize)
    targetRows = max(1, round(targetSize(1)));
    targetCols = max(1, round(targetSize(2)));
    if isempty(imageIn)
        imageOut = zeros(targetRows, targetCols);
        return;
    end
    sourceRows = 1:size(imageIn, 1);
    sourceCols = 1:size(imageIn, 2);
    queryRows = scaledPositions(size(imageIn, 1), targetRows);
    queryCols = scaledPositions(size(imageIn, 2), targetCols);
    [colGrid, rowGrid] = meshgrid(queryCols, queryRows);
    imageOut = interp2(sourceCols, sourceRows, double(imageIn), ...
        colGrid, rowGrid, 'linear', NaN);
end

function positions = scaledPositions(inputLength, outputLength)
    if outputLength <= 1
        positions = 1;
    else
        positions = linspace(1, inputLength, outputLength);
    end
end
