function cal = scaleBarCalibration(referencePixels, referenceLength, unitName, opts)
%SCALEBARCALIBRATION Build a reusable image scale-bar calibration struct.
%
% Usage:
%   cal = labkit.ui.scaleBarCalibration(80, 20, "mm");
%   if cal.isCalibrated
%       physicalLength = pixelLength / cal.pixelsPerUnit;
%   end
%
% Inputs:
%   referencePixels - measured or typed reference length in image pixels.
%                     Nonpositive or nonfinite values are treated as missing.
%   referenceLength - real reference length in the selected unit. Nonpositive
%                     or nonfinite values produce an uncalibrated result.
%   unitName - string-like display unit. The default unit set is
%              {'m','cm','mm','um','nm'}; unsupported values use the default
%              unit.
%   opts - optional struct.
%
% Options:
%   units - allowed unit labels, default {'m','cm','mm','um','nm'}.
%   defaultUnit - fallback unit, default first allowed unit.
%   referenceLine - optional N-by-2 reference endpoint array. When two points
%                   are supplied and referencePixels is missing, their pixel
%                   distance is used.
%
% Output:
%   cal - struct with fields referencePixels, referenceLength, unit,
%         pixelsPerUnit, isCalibrated, and referenceLine.

    if nargin < 1 || isempty(referencePixels)
        referencePixels = NaN;
    end
    if nargin < 2 || isempty(referenceLength)
        referenceLength = 0;
    end
    if nargin < 3 || isempty(unitName)
        unitName = "";
    end
    if nargin < 4
        opts = struct();
    end

    units = cellstr(string(optionValue(opts, 'units', defaultScaleBarUnits())));
    defaultUnit = char(string(optionValue(opts, 'defaultUnit', units{1})));
    referenceLine = normalizeReferenceLine(optionValue(opts, 'referenceLine', zeros(0, 2)));

    referencePixels = positiveOrNaN(referencePixels);
    if ~isfinite(referencePixels) && size(referenceLine, 1) == 2
        referencePixels = hypot(referenceLine(2, 1) - referenceLine(1, 1), ...
            referenceLine(2, 2) - referenceLine(1, 2));
        referencePixels = positiveOrNaN(referencePixels);
    end

    referenceLength = nonnegativeScalar(referenceLength);
    unitName = char(normalizeScaleBarUnit(unitName, units, defaultUnit));
    pixelsPerUnit = 0;
    if isfinite(referencePixels) && referencePixels > 0 && referenceLength > 0
        pixelsPerUnit = referencePixels / referenceLength;
    end

    cal = struct( ...
        'referencePixels', referencePixels, ...
        'referenceLength', referenceLength, ...
        'unit', unitName, ...
        'pixelsPerUnit', pixelsPerUnit, ...
        'isCalibrated', pixelsPerUnit > 0, ...
        'referenceLine', referenceLine);
end

function referenceLine = normalizeReferenceLine(referenceLine)
    if isempty(referenceLine)
        referenceLine = zeros(0, 2);
        return;
    end
    referenceLine = double(referenceLine);
    if size(referenceLine, 2) ~= 2
        referenceLine = zeros(0, 2);
    end
end

function value = positiveOrNaN(value)
    if isempty(value) || ~isnumeric(value) || ~isscalar(value) || ~isfinite(value) || value <= 0
        value = NaN;
    end
end

function value = nonnegativeScalar(value)
    if isempty(value) || ~isnumeric(value) || ~isscalar(value) || ~isfinite(value) || value < 0
        value = 0;
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end
