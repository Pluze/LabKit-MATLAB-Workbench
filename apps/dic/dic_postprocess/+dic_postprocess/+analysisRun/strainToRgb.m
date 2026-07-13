% DIC Postprocess ops helper. Expected caller: labkit_DICPostprocess_app.
% Inputs are strain map, valid-map, target size, and overlay options. Outputs
% are RGB strain colors and resized validity mask. Side effects: none.
function [rgb, validMask] = strainToRgb(strainMap, validMap, targetSize, opts)
    S = dic_postprocess.analysisRun.extendStrainMapToRoi(double(strainMap), validMap);
    if opts.sigmaSmooth > 0
        S = dic_postprocess.analysisRun.gaussianSmooth(S, opts.sigmaSmooth);
    end
    oversample = max(1, round(opts.oversample));
    Sbig = dic_postprocess.analysisRun.resizeLinear( ...
        S, size(S) .* oversample);
    Shr = dic_postprocess.analysisRun.resizeLinear(Sbig, targetSize);
    validMask = dic_postprocess.analysisRun.resizeNearest( ...
        logical(validMap), targetSize) & isfinite(Shr);
    smin = opts.colorRange(1);
    smax = opts.colorRange(2);
    Snorm = (Shr - smin) ./ (smax - smin);
    Snorm = max(min(Snorm, 1), 0);
    idx = ones(size(Snorm));
    idx(validMask) = round(Snorm(validMask) * (size(opts.colormap, 1) - 1)) + 1;
    rgb = ind2rgb(idx, opts.colormap);
end
