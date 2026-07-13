% App-owned unit conversion helper. Expected caller: batch-crop physical
% preview/export calculations. Inputs are a scale calibration struct and the
% requested physical crop unit. Output is pixels per requested unit.
function pixelsPerUnit = pixelsPerUnitForUnit(cal, targetUnit)
%PIXELSPERUNITFORUNIT Convert calibration density to a target unit.

    if nargin < 2 || strlength(string(targetUnit)) == 0
        targetUnit = "um";
    end
    if ~batch_crop.appState.isScaleCalibrationSet(cal)
        pixelsPerUnit = NaN;
        return;
    end

    sourceUnit = fieldValue(cal, 'unit', targetUnit);
    pixelsPerUnit = double(cal.pixelsPerUnit) .* ...
        metersPerUnit(targetUnit) ./ metersPerUnit(sourceUnit);
end

function value = metersPerUnit(unitName)
    % Constant: SI prefix factors convert supported physical length units
    % to meters before calibration densities are compared.
    centimetersToMeters = 1e-2;
    millimetersToMeters = 1e-3;
    micrometersToMeters = 1e-6;
    nanometersToMeters = 1e-9;
    switch string(unitName)
        case "m"
            value = 1;
        case "cm"
            value = centimetersToMeters;
        case "mm"
            value = millimetersToMeters;
        case "um"
            value = micrometersToMeters;
        case "nm"
            value = nanometersToMeters;
        otherwise
            error('labkit_BatchImageCrop_app:InvalidScaleUnit', ...
                'Unsupported physical scale unit: %s.', char(string(unitName)));
    end
end

function value = fieldValue(S, name, defaultValue)
    value = defaultValue;
    if isstruct(S) && isfield(S, name) && ~isempty(S.(name))
        value = S.(name);
    end
end
