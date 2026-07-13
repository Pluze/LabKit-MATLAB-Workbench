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
        rgb = labkit.image.ensureRgb(labkit.image.im2double(imageData));
        gray = labkit.image.rgb2gray(rgb);
    else
        gray = labkit.image.im2double(imageData);
    end
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
