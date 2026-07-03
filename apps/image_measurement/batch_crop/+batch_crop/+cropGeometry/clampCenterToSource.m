% Expected caller: batch crop actions and crop interaction helpers. Inputs are a
% candidate [x y] center and the source image array. Output is a row-vector
% center clamped to the image bounds. No state is mutated.
function centerXY = clampCenterToSource(centerXY, imageData)
%CLAMPCENTERTOSOURCE Clamp a crop center to source image bounds.

    centerXY = double(centerXY(:)).';
    centerXY(1) = min(max(centerXY(1), 1), size(imageData, 2));
    centerXY(2) = min(max(centerXY(2), 1), size(imageData, 1));
end
