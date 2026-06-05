function unitName = normalizeScaleBarUnit(unitName, units, defaultUnit)
%NORMALIZESCALEBARUNIT Normalize a scale-bar unit against allowed UI units.
%
% Expected caller:
%   labkit.ui scale-bar calibration and control helpers.
%
% Inputs/outputs:
%   unitName - string-like candidate value.
%   units - allowed unit labels as a cellstr/string array.
%   defaultUnit - fallback unit label.
%   Returns one string scalar from units, or defaultUnit when no match exists.
%
% Side effects:
%   None.

    units = string(units);
    if isempty(units)
        units = string(defaultScaleBarUnits());
    end
    defaultUnit = string(defaultUnit);
    if ~any(defaultUnit == units)
        defaultUnit = units(1);
    end

    unitName = string(unitName);
    idx = find(unitName == units, 1);
    if isempty(idx)
        unitName = defaultUnit;
    else
        unitName = units(idx);
    end
end
