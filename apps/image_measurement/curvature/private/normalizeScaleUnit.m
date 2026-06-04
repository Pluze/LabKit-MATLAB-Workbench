function scaleUnit = normalizeScaleUnit(scaleUnit)
%NORMALIZESCALEUNIT Normalize app-owned scale units.
%
% Expected caller:
%   labkit_CurvatureMeasurement_app private scale, length, and fit helpers.
%
% Inputs/outputs:
%   String-like scale unit. Returns one of "nm", "um", "mm", or "cm",
%   defaulting to "um" for unsupported values.
%
% Side effects:
%   None.

    scaleUnit = string(scaleUnit);
    validUnits = ["nm", "um", "mm", "cm"];
    if ~any(scaleUnit == validUnits)
        scaleUnit = "um";
    end
end
