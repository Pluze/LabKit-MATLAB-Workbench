% App-owned geometry helper. Expected caller: batch-crop preview and center
% callbacks. Inputs are source image width and height in pixels. Output is the
% one-based center coordinate [x y] in source-image coordinates.
function centerXY = sourceCenterFromSize(width, height)
%SOURCECENTERFROMSIZE Return the one-based geometric source center.

    centerXY = [(width + 1) / 2, (height + 1) / 2];
end
