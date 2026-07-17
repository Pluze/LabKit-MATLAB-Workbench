function [curve, owners] = anchorPath(points, imageSize, options)
%ANCHORPATH Build a visible path through image anchor points.
%
% Usage:
%   curve = labkit.ui.interaction.anchorPath(points, imageSize)
%   curve = labkit.ui.interaction.anchorPath(points, imageSize, Name=Value)
%   [curve, owners] = labkit.ui.interaction.anchorPath(...)
%
% Inputs:
%   points - N-by-2 numeric matrix of [x y] anchor coordinates in image-pixel
%       coordinates.
%   imageSize - Numeric vector whose first two elements are the positive finite
%       image height and width.
%   options - Name-value argument container for Style and Closed. Supply these
%       values by name; do not pass an options struct.
%
% Name-Value Arguments:
%   Style - "Curve" for a Catmull-Rom path or "Straight lines" for line
%       segments joining the anchors. Default: "Curve".
%   Closed - Logical scalar. true joins the last anchor to the first and
%       requires at least three anchors. false requires at least two. Default:
%       false.
%
% Outputs:
%   curve - M-by-2 path samples. Coordinates are limited to pixel-edge bounds
%       [0.5, width+0.5] and [0.5, height+0.5]. The result is empty until the
%       selected open or closed path has enough anchors.
%   owners - (M-1)-by-1 anchor-segment indices used to associate each visible
%       curve segment with its starting anchor. It is empty with curve.
%
% Description:
%   anchorPath contains the deterministic geometry shared by managed anchor
%   editors and app previews. Curved paths pass through the supplied anchors;
%   two-point open curves reduce to a straight segment. The function creates no
%   graphics and can be used independently of a LabKit app.
%
% Errors:
%   MATLAB argument-validation or assertion errors are raised when points is
%   not N-by-2, imageSize lacks positive finite height and width, Style is
%   unsupported, or a named argument has an incompatible type or shape.
%
% Example:
%   points = [10 30; 30 10; 50 30];
%   curve = labkit.ui.interaction.anchorPath( ...
%       points, [40 60], "Style", "Straight lines");
%   assert(isequal(curve, points))
%
% See also labkit.ui.runtime.define

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
    [curve, owners] = anchorCurvePoints(points, imageSize, ...
        options.Style, options.Closed);
end
