% Expected caller: FLIR thermal ROI export and tests. Inputs are one app item
% with roiRect and calibrated temperatures. Outputs are the cropped Celsius
% matrix and integer ROI rectangle [x y w h]; no file or GUI side effects.
function [values, rect] = roiTemperatureMatrix(item)

    matrix = flir_thermal.export.temperatureMatrix(item);
    if ~isfield(item, 'roiRect') || isempty(item.roiRect)
        error('labkit_FLIRThermal_app:NoRoiSelected', ...
            'No ROI is selected for %s.', char(string(item.name)));
    end
    rect = clampRect(item.roiRect, size(matrix));
    values = matrix(rect(2):(rect(2) + rect(4) - 1), ...
        rect(1):(rect(1) + rect(3) - 1));
end

function rect = clampRect(rect, imageSize)
    rect = double(rect(:)).';
    if numel(rect) ~= 4 || ~all(isfinite(rect)) || any(rect(3:4) <= 0)
        error('labkit_FLIRThermal_app:InvalidRoi', ...
            'ROI must be a finite [x y width height] rectangle.');
    end
    height = imageSize(1);
    width = imageSize(2);
    x1 = max(1, min(width, floor(rect(1))));
    y1 = max(1, min(height, floor(rect(2))));
    x2 = max(x1, min(width, ceil(rect(1) + rect(3) - 1)));
    y2 = max(y1, min(height, ceil(rect(2) + rect(4) - 1)));
    rect = [x1, y1, x2 - x1 + 1, y2 - y1 + 1];
end
