% Expected caller: DIC preprocess runner and direct unit tests. Inputs are the
% reference image and current moving/aligned image. Output is the false-color
% registration preview image. Side effects: none.

function overlay = makeFalseColorOverlay(referenceImage, alignedImage)
%MAKEFALSECOLOROVERLAY Build DIC preprocess false-color pair preview.

    refGray = normalizeGray(referenceImage);
    movGray = normalizeGray(alignedImage);
    if ~isequal(size(refGray), size(movGray))
        movGray = resizeNearest(movGray, size(refGray));
    end
    overlay = zeros([size(refGray), 3]);
    overlay(:, :, 1) = movGray;
    overlay(:, :, 2) = refGray;
end

function imageOut = resizeNearest(imageIn, targetSize)
    targetRows = max(1, round(targetSize(1)));
    targetCols = max(1, round(targetSize(2)));
    rowIdx = nearestIndices(size(imageIn, 1), targetRows);
    colIdx = nearestIndices(size(imageIn, 2), targetCols);
    imageOut = imageIn(rowIdx, colIdx, :);
end

function idx = nearestIndices(inputLength, outputLength)
    if outputLength <= 1
        idx = 1;
        return;
    end
    positions = linspace(1, inputLength, outputLength);
    idx = min(max(round(positions), 1), inputLength);
end

function gray = normalizeGray(imageData)
    if ndims(imageData) == 3
        gray = labkit.image.toLuma(imageData);
    else
        gray = imageData;
    end
    gray = localIm2double(gray);
    values = gray(:);
    values = values(~isnan(values));
    if isempty(values)
        return;
    end
    mn = min(values);
    mx = max(values);
    if isfinite(mn) && isfinite(mx) && mx > mn
        gray = (gray - mn) ./ (mx - mn);
    end
end

function imageOut = localIm2double(imageIn)
    if isfloat(imageIn)
        imageOut = double(imageIn);
    elseif isa(imageIn, 'uint8')
        imageOut = double(imageIn) ./ double(intmax('uint8'));
    elseif isa(imageIn, 'uint16')
        imageOut = double(imageIn) ./ double(intmax('uint16'));
    elseif isa(imageIn, 'int16')
        imageOut = (double(imageIn) - double(intmin('int16'))) ./ ...
            double(intmax('int16') - intmin('int16'));
    else
        imageOut = double(imageIn);
    end
end
