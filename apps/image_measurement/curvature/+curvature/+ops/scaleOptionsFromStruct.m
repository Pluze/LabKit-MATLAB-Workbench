% App-owned image measurement package helper. Expected caller: owning app callbacks
% and package tests. Inputs, outputs, and side effects are
% documented with the helper function below.
function calibration = scaleOptionsFromStruct(opts)
%SCALEOPTIONSFROMSTRUCT Normalize test and app scale options.
%
% Expected caller:
%   labkit_CurvatureMeasurement_app package tests.
%
% Inputs/outputs:
%   Option struct with current and legacy scale fields. Returns a GUI-free
%   calibration struct for curvature calculations.
%
% Side effects:
%   None.

    if isstruct(opts) && isfield(opts, 'calibration') && isstruct(opts.calibration)
        calibration = opts.calibration;
        return;
    end

    referencePx = curvature.ops.optionValue(opts, 'referencePx', ...
        curvature.ops.optionValue(opts, 'rawpx', NaN));
    referenceLength = curvature.ops.optionValue(opts, 'referenceLength', ...
        curvature.ops.optionValue(opts, 'scaleLengthMm', 0));
    scaleUnit = curvature.ops.optionValue(opts, 'scaleUnit', '');
    referencePx = positiveOrNaN(referencePx);
    if isempty(referenceLength) || ~isfinite(referenceLength) || referenceLength < 0
        referenceLength = 0;
    end

    manualPxPerMm = curvature.ops.optionValue(opts, 'manualPxPerMm', 0);
    if isempty(manualPxPerMm) || ~isfinite(manualPxPerMm) || manualPxPerMm < 0
        manualPxPerMm = 0;
    end
    if ~(isfinite(referencePx) && referencePx > 0 && referenceLength > 0) && manualPxPerMm > 0
        referencePx = manualPxPerMm;
        referenceLength = 1;
        scaleUnit = 'mm';
    end
    calibration = curvature.ops.normalizeScaleCalibration(referencePx, ...
        referenceLength, scaleUnit);
end

function value = positiveOrNaN(value)
    if isempty(value) || ~isfinite(value) || value <= 0
        value = NaN;
    end
end
