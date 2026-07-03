% App-owned curvature calculation helper. Expected caller: curvature ops and
% package tests. Input is a partial calibration struct or raw scale fields.
% Output is a GUI-free calibration struct. Side effects: none.
function calibration = normalizeScaleCalibration(referencePixels, referenceLength, scaleUnit, opts)
%NORMALIZESCALECALIBRATION Normalize scale calibration for curvature ops.

    if nargin == 1 && isstruct(referencePixels)
        existing = referencePixels;
        referencePixels = fieldValue(existing, 'referencePixels', NaN);
        referenceLength = fieldValue(existing, 'referenceLength', 0);
        scaleUnit = fieldValue(existing, 'unit', '');
        opts = struct('referenceLine', fieldValue(existing, ...
            'referenceLine', zeros(0, 2)));
    else
        if nargin < 1
            referencePixels = NaN;
        end
        if nargin < 2
            referenceLength = 0;
        end
        if nargin < 3
            scaleUnit = '';
        end
        if nargin < 4
            opts = struct();
        end
    end

    referenceLine = normalizeReferenceLine(fieldValue(opts, ...
        'referenceLine', zeros(0, 2)));
    referencePixels = positiveOrNaN(referencePixels);
    if ~isfinite(referencePixels) && size(referenceLine, 1) == 2
        referencePixels = hypot(referenceLine(2, 1) - referenceLine(1, 1), ...
            referenceLine(2, 2) - referenceLine(1, 2));
        referencePixels = positiveOrNaN(referencePixels);
    end
    referenceLength = nonnegativeScalar(referenceLength);
    scaleUnit = normalizeUnit(scaleUnit);
    pixelsPerUnit = 0;
    if isfinite(referencePixels) && referencePixels > 0 && referenceLength > 0
        pixelsPerUnit = referencePixels / referenceLength;
    end

    calibration = struct( ...
        'referencePixels', referencePixels, ...
        'referenceLength', referenceLength, ...
        'unit', scaleUnit, ...
        'pixelsPerUnit', pixelsPerUnit, ...
        'isCalibrated', pixelsPerUnit > 0, ...
        'referenceLine', referenceLine);
end

function value = fieldValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
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
    if isempty(value) || ~isnumeric(value) || ~isscalar(value) || ...
            ~isfinite(value) || value <= 0
        value = NaN;
    end
end

function value = nonnegativeScalar(value)
    if isempty(value) || ~isnumeric(value) || ~isscalar(value) || ...
            ~isfinite(value) || value < 0
        value = 0;
    end
end

function unit = normalizeUnit(unit)
    allowed = {'m', 'cm', 'mm', 'um', 'nm'};
    unit = char(string(unit));
    if ~any(strcmp(unit, allowed))
        unit = allowed{1};
    end
end
