% App-owned curvature options adapter. Expected caller: curvature tests and
% advanced debug code. Inputs are curve points plus app option struct; output is
% the same fit struct returned by computeCurvatureFit. No GUI or file side effects.
function fit = computeFitFromOptions(xPix, yPix, opts)
%COMPUTEFITFROMOPTIONS Fit curvature from app-style option fields.

    if nargin < 3
        opts = struct();
    end

    calibration = curvature.ops.scaleOptionsFromStruct(opts);
    doDensify = curvature.ops.optionValue(opts, 'doDensify', true);
    denseN = curvature.ops.optionValue(opts, 'denseN', 300);
    fitPathX = curvature.ops.optionValue(opts, 'fitPathX', []);
    fitPathY = curvature.ops.optionValue(opts, 'fitPathY', []);

    fit = curvature.ops.computeCurvatureFit(xPix, yPix, calibration, ...
        doDensify, denseN, fitPathX, fitPathY);
end
