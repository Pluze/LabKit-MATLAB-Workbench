% DIC Postprocess ops helper. Expected caller: labkit_DICPostprocess_app.
% Inputs are reference image, strain map, display mask, ROI mask, and overlay
% options. Output is the rendered overlay image. Side effects: none.
function overlay = makeStrainOverlay(referenceImage, strainMap, mask, roiMask, opts)
    orig = dic_postprocess.analysisRun.enhanceReferenceImage(referenceImage, opts);
    [H, W, ~] = size(orig);
    mask = imresize(logical(mask), [H W], 'nearest');
    validMap = dic_postprocess.analysisRun.strainValidMask( ...
        strainMap, roiMask, mask, edgeTrimFromOptions(opts));
    [strainRgb, validStrain] = dic_postprocess.analysisRun.strainToRgb( ...
        strainMap, validMap, [H W], opts);
    overlayMask = mask & validStrain;
    mask3 = repmat(overlayMask, [1 1 3]);
    overlay = orig;
    overlay(mask3) = (1 - opts.alpha) .* orig(mask3) + opts.alpha .* strainRgb(mask3);
end

function edgeTrim = edgeTrimFromOptions(opts)
    edgeTrim = 1;
    if isstruct(opts) && isfield(opts, 'edgeTrim')
        edgeTrim = max(0, round(opts.edgeTrim));
    end
end
