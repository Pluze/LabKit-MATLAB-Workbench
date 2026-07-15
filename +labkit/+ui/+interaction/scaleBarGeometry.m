function geometry = scaleBarGeometry(imageSize, calibration, barLength, position, colorName)
%SCALEBARGEOMETRY Build serializable image scale-bar overlay geometry.
%
% Usage:
%   cal = labkit.ui.interaction.scaleBarCalibration(80, 20, "mm");
%   geometry = labkit.ui.interaction.scaleBarGeometry( ...
%       size(imageData), cal, 10, "Bottom right", "White");
%
% Inputs:
%   imageSize - source image size; the first two elements are height/width.
%   calibration - scaleBarCalibration-compatible struct with positive
%       pixelsPerUnit and a unit label.
%   barLength - positive physical length expressed in calibration.unit.
%   position - Bottom/Top combined with left/center/right. Default is
%       "Bottom right" when the supplied value has no recognized token.
%   colorName - "Black" or "White"; other values fall back to black.
%
% Output:
%   geometry - scalar data struct with line, label, color, labelPosition,
%       verticalAlignment, pixelsPerUnit, unit, barLength, position, and
%       colorName. Apps/renderers own drawing; this function creates no UI.

    imageSize = double(imageSize);
    assert(numel(imageSize) >= 2 && all(isfinite(imageSize(1:2))) && ...
        all(imageSize(1:2) > 0), ...
        'labkit:ui:interaction:InvalidImageSize', ...
        'Image size must provide positive finite height and width.');
    pixelsPerUnit = double(calibration.pixelsPerUnit);
    barLength = double(barLength);
    assert(isscalar(pixelsPerUnit) && isfinite(pixelsPerUnit) && ...
        pixelsPerUnit > 0 && isscalar(barLength) && ...
        isfinite(barLength) && barLength > 0, ...
        'labkit:ui:interaction:InvalidScaleBar', ...
        'A positive calibration and scale-bar length are required.');
    height = imageSize(1);
    width = imageSize(2);
    barPixels = barLength * pixelsPerUnit;
    % Constant: 8% with a five-pixel floor preserves a visible image-edge
    % inset across thumbnail and full-resolution preview sizes.
    marginFraction = 0.08;
    minimumMarginPixels = 5;
    margin = max(minimumMarginPixels, min(width, height) * marginFraction);
    available = width - 2 * margin;
    assert(barPixels <= available, ...
        'labkit:ui:interaction:ScaleBarTooLong', ...
        ['Scale bar is %.6g px, but the image only has %.6g px ' ...
        'available horizontally.'], barPixels, available);
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
    % Constant: twelve pixels separates the standard workbench label from
    % its line without obscuring the measurement reference.
    value = 12;
end
