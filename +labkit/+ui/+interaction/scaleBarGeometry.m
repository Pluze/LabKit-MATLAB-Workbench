function geometry = scaleBarGeometry(imageSize, calibration, barLength, position, colorName)
%SCALEBARGEOMETRY Compute serializable image scale-bar overlay geometry.
%
% Usage:
%   geometry = labkit.ui.interaction.scaleBarGeometry(imageSize, ...
%       calibration, barLength, position, colorName)
%
% Inputs:
%   imageSize - Numeric vector whose first two elements are positive finite
%       image height and width in pixels.
%   calibration - Struct with a positive finite pixelsPerUnit field and a unit
%       field, normally returned by scaleBarCalibration.
%   barLength - Positive finite physical length expressed in calibration.unit.
%   position - Text containing "top" or "bottom" and optionally "left",
%       "center", or "right". Unrecognized vertical text uses bottom;
%       unrecognized horizontal text uses center.
%   colorName - "White" selects [1 1 1]. Every other value selects black.
%
% Outputs:
%   geometry - Scalar data struct with the fields described below.
%
% Geometry Fields:
%   line - Two-by-two [x y] endpoints in image-pixel coordinates.
%   label - Display text containing barLength and calibration.unit.
%   color - RGB triplet selected by colorName.
%   labelPosition - One-by-two centered label position in image pixels.
%   verticalAlignment - "top" for a top bar or "bottom" for a bottom bar.
%   pixelsPerUnit - Calibration value copied into the geometry.
%   unit - Unit label copied into the geometry as a string scalar.
%   barLength - Requested physical length.
%   position - Supplied position text as a string scalar.
%   colorName - Supplied color text as a string scalar.
%
% Description:
%   The helper places the line with an eight-percent image-edge margin and a
%   five-pixel minimum inset. It errors when the requested bar cannot fit in the
%   available horizontal span. Apps and renderers own drawing; this function
%   creates no graphics and is suitable for saved project state.
%
% Errors:
%   labkit:ui:interaction:InvalidImageSize - imageSize lacks positive finite
%   height and width.
%   labkit:ui:interaction:InvalidScaleBar - calibration or barLength is not a
%   positive finite scalar.
%   labkit:ui:interaction:ScaleBarTooLong - The requested bar does not fit
%   inside the horizontal margins.
%
% Example:
%   cal = labkit.ui.interaction.scaleBarCalibration(80, 20, "mm");
%   geometry = labkit.ui.interaction.scaleBarGeometry( ...
%       [600 800], cal, 10, "Bottom right", "White");
%   assert(abs(diff(geometry.line(:,1))) == 40)
%
% See also labkit.ui.interaction.scaleBarCalibration

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
