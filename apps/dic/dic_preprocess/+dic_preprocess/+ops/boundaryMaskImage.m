% Expected caller: DIC preprocess runner and direct unit tests. Inputs are ROI
% boundary points, image size, and boundary style. Output is a uint8 binary mask
% with 255 inside the ROI. Side effects: none.

function mask = boundaryMaskImage(points, imageSize, boundaryStyle)
%BOUNDARYMASKIMAGE Rasterize a DIC preprocess ROI boundary.

    curve = dic_preprocess.ops.maskBoundaryCurve(points, imageSize, boundaryStyle);
    mask = dic_preprocess.ops.maskFromCurve(curve, imageSize);
end
