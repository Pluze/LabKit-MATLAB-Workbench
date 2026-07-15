% Expected caller: Batch Crop V2 actions. Inputs are source image size,
% calibration, requested physical bar length, position, and color. Output is
% serializable source-image overlay geometry; side effects are none.
function geometry = scaleBarGeometry(imageSize, calibration, barLength, position, colorName)
    pixelsPerUnit = double(calibration.pixelsPerUnit);
    barLength = double(barLength);
    assert(isfinite(pixelsPerUnit) && pixelsPerUnit > 0 && ...
        isfinite(barLength) && barLength > 0, ...
        'batch_crop:InvalidScaleBar', ...
        'A positive calibration and scale-bar length are required.');
    height = double(imageSize(1));
    width = double(imageSize(2));
    barPixels = barLength * pixelsPerUnit;
    % Constant: scale-bar placement keeps an 8% inset with a five-pixel
    % minimum so labels and lines remain clear of image edges.
    marginFraction = 0.08;
    minimumMarginPixels = 5;
    margin = max(minimumMarginPixels, min(width, height) * marginFraction);
    available = width - 2 * margin;
    assert(barPixels <= available, 'batch_crop:ScaleBarTooLong', ...
        'Scale bar is %.6g px, but the image only has %.6g px available horizontally.', ...
        barPixels, available);
    position = string(position);
    if contains(position, "left", 'IgnoreCase', true)
        x1 = margin + 0.5;
    elseif contains(position, "right", 'IgnoreCase', true)
        x1 = width - margin - barPixels + 0.5;
    else
        x1 = (width - barPixels) / 2 + 0.5;
    end
    if contains(position, "top", 'IgnoreCase', true)
        y = margin + 0.5;
        labelY = y + labelOffsetPixels();
        verticalAlignment = "top";
    else
        y = height - margin + 0.5;
        labelY = y - labelOffsetPixels();
        verticalAlignment = "bottom";
    end
    line = [x1, y; x1 + barPixels, y];
    color = [0 0 0];
    if strcmpi(string(colorName), "White")
        color = [1 1 1];
    end
    geometry = struct( ...
        "line", line, ...
        "label", sprintf('%.6g %s', barLength, calibration.unit), ...
        "color", color, ...
        "labelPosition", [mean(line(:, 1)), labelY], ...
        "verticalAlignment", verticalAlignment, ...
        "pixelsPerUnit", pixelsPerUnit, ...
        "unit", string(calibration.unit), ...
        "barLength", barLength, ...
        "position", position, ...
        "colorName", string(colorName));
end

function value = labelOffsetPixels()
    % Constant: twelve pixels separates the scale label from its line at
    % the standard workbench font size.
    value = 12;
end
