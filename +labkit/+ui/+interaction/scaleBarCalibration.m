function cal = scaleBarCalibration(referencePixels, referenceLength, unitName, opts)
%SCALEBARCALIBRATION Convert a known image distance into pixels per unit.
%
% Usage:
%   cal = labkit.ui.interaction.scaleBarCalibration(referencePixels, ...
%       referenceLength, unitName)
%   cal = labkit.ui.interaction.scaleBarCalibration(..., opts)
%
% Inputs:
%   referencePixels - Measured reference distance in image pixels. Empty,
%       nonnumeric, nonfinite, or nonpositive values are treated as missing.
%   referenceLength - Physical reference distance expressed in unitName.
%       Missing, nonfinite, or negative values become 0.
%   unitName - Unit label. With default options, legal values are "m", "cm",
%       "mm", "um", and "nm". An unsupported value uses defaultUnit.
%   opts - Optional scalar struct described below. Default: struct().
%
% Options:
%   units - Allowed unit labels. Default: {'m','cm','mm','um','nm'}.
%   defaultUnit - Fallback unit. Default: the first entry in units.
%   referenceLine - N-by-2 numeric reference points stored with the result.
%       When it contains exactly two rows and referencePixels is missing, their
%       Euclidean distance supplies referencePixels. Default: zeros(0,2).
%
% Outputs:
%   cal - Scalar struct with the fields described below.
%
% Calibration Fields:
%   referencePixels - Positive measured pixel distance, or NaN when missing.
%   referenceLength - Nonnegative physical reference distance.
%   unit - Normalized unit label as a character vector.
%   pixelsPerUnit - referencePixels/referenceLength, or 0 when calibration is
%       incomplete.
%   isCalibrated - true when pixelsPerUnit is positive.
%   referenceLine - Normalized N-by-2 numeric reference coordinates.
%
% Description:
%   This function builds a serializable calibration value; it does not read an
%   image or draw a scale bar. Repeating the call with identical inputs returns
%   identical numeric fields. Divide a pixel distance by pixelsPerUnit to obtain
%   a distance in cal.unit.
%
% Failure Behavior:
%   Missing or invalid measurement values are normalized into an uncalibrated
%   result instead of throwing. opts must be a scalar structure whose units
%   can be converted to text and whose referenceLine can be converted to an
%   N-by-2 numeric array; incompatible MATLAB values propagate conversion
%   errors.
%
% Example:
%   cal = labkit.ui.interaction.scaleBarCalibration(80, 20, "mm");
%   physicalLength = 40 / cal.pixelsPerUnit;
%   assert(cal.isCalibrated && physicalLength == 10)
%
% See also labkit.ui.interaction.scaleBarGeometry

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
