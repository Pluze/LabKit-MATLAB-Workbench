% App-owned scale-state normalization helper. Expected caller: batch-crop UI
% scale-unit synchronization. Inputs are a calibration-like struct and unit.
% Output is a calibration-like struct with the same numeric calibration.
function cal = withScaleUnit(cal, unitName)
%WITHSCALEUNIT Return calibration with an updated display unit label.

    if ~isstruct(cal)
        cal = batch_crop.appState.emptyScaleCalibration(unitName);
        return;
    end
    cal = struct( ...
        'referencePixels', numericField(cal, 'referencePixels', NaN), ...
        'referenceLength', numericField(cal, 'referenceLength', 1), ...
        'unit', char(string(unitName)), ...
        'pixelsPerUnit', numericField(cal, 'pixelsPerUnit', 0), ...
        'isCalibrated', logicalField(cal, 'isCalibrated', false), ...
        'referenceLine', referenceLineField(cal));
end

function value = numericField(s, name, defaultValue)
    value = defaultValue;
    if isstruct(s) && isfield(s, name) && ~isempty(s.(name)) && ...
            isnumeric(s.(name)) && isscalar(s.(name)) && isfinite(double(s.(name)))
        value = double(s.(name));
    end
end

function value = logicalField(s, name, defaultValue)
    value = defaultValue;
    if isstruct(s) && isfield(s, name) && ~isempty(s.(name))
        value = logical(s.(name));
    end
end

function line = referenceLineField(s)
    line = zeros(0, 2);
    if ~isstruct(s) || ~isfield(s, 'referenceLine') || isempty(s.referenceLine)
        return;
    end
    candidate = double(s.referenceLine);
    if size(candidate, 2) == 2 && all(isfinite(candidate(:)))
        line = candidate;
    end
end
