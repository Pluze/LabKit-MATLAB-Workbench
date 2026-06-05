% App-owned DIC helper extracted from labkit_DICPostprocess_app.m. Expected caller: DIC app entrypoints.
% Inputs, outputs, and side effects match the original local helper implementation.
function overlay = makeStrainOverlay(referenceImage, strainMap, mask, roiMask, opts)
    orig = enhanceReferenceImage(referenceImage, opts);
    [H, W, ~] = size(orig);
    mask = imresize(logical(mask), [H W], 'nearest');
    validMap = strainValidMask(strainMap, roiMask, mask);
    [strainRgb, validStrain] = strainToRgb(strainMap, validMap, [H W], opts);
    overlayMask = mask & validStrain;
    mask3 = repmat(overlayMask, [1 1 3]);
    overlay = orig;
    overlay(mask3) = (1 - opts.alpha) .* orig(mask3) + opts.alpha .* strainRgb(mask3);
end
