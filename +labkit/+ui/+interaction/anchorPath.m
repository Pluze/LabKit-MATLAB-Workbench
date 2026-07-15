function curve = anchorPath(points, imageSize, options)
%ANCHORPATH Build the visible path used by a managed anchor interaction.
%
% Inputs:
%   points - N-by-2 image-pixel anchor coordinates.
%   imageSize - image size with height and width in the first two elements.
%   options - optional name-value arguments:
%       Style  - "Curve" (default) or "Straight lines".
%       Closed - logical scalar, default false.
%
% Output:
%   curve - M-by-2 visible path samples, clamped to the image bounds. Empty
%           until enough anchors exist for the selected open/closed path.
%
% Example:
%   curve = labkit.ui.interaction.anchorPath(points, size(imageData), ...
%       "Style", "Curve", "Closed", false);

    arguments
        points double
        imageSize double
        options.Style (1, 1) string = "Curve"
        options.Closed (1, 1) logical = false
    end
    assert(isempty(points) || size(points, 2) == 2, ...
        'Anchor points must be an N-by-2 numeric array.');
    assert(numel(imageSize) >= 2 && all(isfinite(imageSize(1:2))) && ...
        all(imageSize(1:2) > 0), ...
        'Image size must contain positive finite height and width values.');
    assert(any(options.Style == ["Curve", "Straight lines"]), ...
        'Style must be "Curve" or "Straight lines".');
    curve = anchorCurvePoints(points, imageSize, ...
        options.Style, options.Closed);
end
