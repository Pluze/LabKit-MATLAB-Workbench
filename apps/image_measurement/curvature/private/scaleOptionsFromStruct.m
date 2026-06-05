function calibration = scaleOptionsFromStruct(opts)
%SCALEOPTIONSFROMSTRUCT Normalize test and app scale options.
%
% Expected caller:
%   labkit_CurvatureMeasurement_app __labkit_test__ handlers.
%
% Inputs/outputs:
%   Option struct with current and legacy scale fields. Returns a
%   labkit.ui scale-bar calibration struct.
%
% Side effects:
%   None.

    if isstruct(opts) && isfield(opts, 'calibration') && isstruct(opts.calibration)
        calibration = opts.calibration;
        return;
    end

    referencePx = optionValue(opts, 'referencePx', optionValue(opts, 'rawpx', NaN));
    referenceLength = optionValue(opts, 'referenceLength', optionValue(opts, 'scaleLengthMm', 0));
    scaleUnit = optionValue(opts, 'scaleUnit', '');
    referencePx = positiveOrNaN(referencePx);
    if isempty(referenceLength) || ~isfinite(referenceLength) || referenceLength < 0
        referenceLength = 0;
    end

    manualPxPerMm = optionValue(opts, 'manualPxPerMm', 0);
    if isempty(manualPxPerMm) || ~isfinite(manualPxPerMm) || manualPxPerMm < 0
        manualPxPerMm = 0;
    end
    if ~(isfinite(referencePx) && referencePx > 0 && referenceLength > 0) && manualPxPerMm > 0
        referencePx = manualPxPerMm;
        referenceLength = 1;
        scaleUnit = 'mm';
    end
    calibration = labkit.ui.tool.scaleBarCalibration(referencePx, referenceLength, scaleUnit);
end

function value = positiveOrNaN(value)
    if isempty(value) || ~isfinite(value) || value <= 0
        value = NaN;
    end
end
