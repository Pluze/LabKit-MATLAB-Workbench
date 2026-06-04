function [referencePx, referenceLength, scaleUnit] = scaleOptionsFromStruct(opts)
%SCALEOPTIONSFROMSTRUCT Normalize test and app scale options.
%
% Expected caller:
%   labkit_CurvatureMeasurement_app __labkit_test__ handlers.
%
% Inputs/outputs:
%   Option struct with current and legacy scale fields. Returns normalized
%   reference pixels, reference length, and display unit.
%
% Side effects:
%   None.

    referencePx = optionValue(opts, 'referencePx', optionValue(opts, 'rawpx', NaN));
    referenceLength = optionValue(opts, 'referenceLength', optionValue(opts, 'scaleLengthMm', 0));
    scaleUnit = optionValue(opts, 'scaleUnit', 'um');
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
    scaleUnit = char(normalizeScaleUnit(scaleUnit));
end

function value = positiveOrNaN(value)
    if isempty(value) || ~isfinite(value) || value <= 0
        value = NaN;
    end
end
