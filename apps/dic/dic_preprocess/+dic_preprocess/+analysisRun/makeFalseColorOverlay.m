% Expected caller: DIC preprocess runner and direct unit tests. Inputs are the
% reference image and current moving/aligned image. Output is the false-color
% registration preview image. Side effects: none.

function overlay = makeFalseColorOverlay(referenceImage, alignedImage)
%MAKEFALSECOLOROVERLAY Build DIC preprocess false-color pair preview.

    refGray = normalizeGray(referenceImage);
    movGray = normalizeGray(alignedImage);
    if ~isequal(size(refGray), size(movGray))
        movGray = imresize(movGray, size(refGray), 'nearest');
    end
    overlay = zeros([size(refGray), 3]);
    overlay(:, :, 1) = movGray;
    overlay(:, :, 2) = refGray;
end

function gray = normalizeGray(imageData)
    if ndims(imageData) == 3
        gray = rgb2gray(imageData);
    else
        gray = imageData;
    end
    gray = im2double(gray);
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
