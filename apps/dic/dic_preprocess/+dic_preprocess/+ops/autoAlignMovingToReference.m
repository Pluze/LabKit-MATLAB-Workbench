% Expected caller: DIC preprocess runner. Inputs are the current reference and
% moving images. Outputs are the phase-correlation aligned image, transform, and
% user-facing method label. Side effects: none.

function [alignedImage, tformRigid, method] = autoAlignMovingToReference(referenceImage, movingImage)
%AUTOALIGNMOVINGTOREFERENCE Automatically align moving image to reference image.

    origClass = class(movingImage);
    fixedGray = normalizeGray(referenceImage);
    movingGray = normalizeGray(movingImage);

    try
        tformRigid = imregcorr(movingGray, fixedGray, 'rigid');
        method = 'phase-correlation rigid registration';
    catch
        tformRigid = imregcorr(movingGray, fixedGray, 'translation');
        method = 'phase-correlation translation registration';
    end

    Rfixed = imref2d(size(fixedGray));
    alignedImage = imwarp(movingImage, tformRigid, ...
        'OutputView', Rfixed, 'FillValues', 0);
    alignedImage = cast(alignedImage, origClass);
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
