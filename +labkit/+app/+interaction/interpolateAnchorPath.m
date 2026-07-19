function [path, segmentOwners] = interpolateAnchorPath( ...
        points, imageSize, options)
%INTERPOLATEANCHORPATH Build a visible path through image anchor points.
%
% Usage:
%   path = labkit.app.interaction.interpolateAnchorPath(points,imageSize)
%   path = labkit.app.interaction.interpolateAnchorPath( ...
%       points,imageSize,Name=Value)
%   [path,segmentOwners] = labkit.app.interaction.interpolateAnchorPath(...)
%
% Inputs:
%   points - N-by-2 [x y] image-pixel anchor coordinates.
%   imageSize - Dimensions beginning with positive height and width.
%
% Options:
%   Style - "Curve" or "Straight lines". Default: "Curve".
%   Closed - Join last anchor to first. Default: false.
%
% Outputs:
%   path - Interpolated, image-bounded M-by-2 points.
%   segmentOwners - Anchor index owning each path segment.
%
% Errors:
%   MATLAB validation errors are raised for malformed points, dimensions,
%   style, or closed-path options.
%
% Example:
%   points = [10 30;30 10;50 30];
%   path = labkit.app.interaction.interpolateAnchorPath( ...
%       points,[40 60],Style="Straight lines");
%   assert(isequal(path,points))
%
% See also labkit.app.interaction.anchorPath
arguments
    points double
    imageSize double
    options.Style (1,1) string = "Curve"
    options.Closed (1,1) logical = false
end
[path, segmentOwners] = labkit.ui.interaction.anchorPath( ...
    points, imageSize, Style=options.Style, Closed=options.Closed);
end
