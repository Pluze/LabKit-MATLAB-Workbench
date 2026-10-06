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

    calibration = labkit.app.interaction.scaleCalibration( ...
        referencePixels, referenceLength, scaleUnit, ...
        struct('referenceLine', fieldValue(opts, 'referenceLine', zeros(0, 2))));
end

function value = fieldValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end
