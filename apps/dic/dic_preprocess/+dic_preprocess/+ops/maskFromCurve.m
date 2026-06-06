% Expected caller: DIC preprocess runner and direct unit tests. Inputs are a
% closed ROI boundary curve and image size. Output is a uint8 binary mask with
% 255 inside the ROI. Side effects: none.

function mask = maskFromCurve(curve, imageSize)
%MASKFROMCURVE Rasterize a closed ROI curve into a binary mask image.

    H = imageSize(1);
    W = imageSize(2);
    if isempty(curve)
        mask = uint8(false(H, W));
        return;
    end
    mask = uint8(poly2mask(curve(:, 1), curve(:, 2), H, W)) .* uint8(255);
end
