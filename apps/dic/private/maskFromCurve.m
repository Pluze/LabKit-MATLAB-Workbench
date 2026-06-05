% App-owned DIC helper extracted from labkit_DICPreprocess_app.m. Expected caller: DIC app entrypoints.
% Inputs, outputs, and side effects match the original local helper implementation.
function mask = maskFromCurve(curve, imageSize)
    H = imageSize(1);
    W = imageSize(2);
    if isempty(curve)
        mask = uint8(false(H, W));
        return;
    end
    mask = uint8(poly2mask(curve(:, 1), curve(:, 2), H, W)) .* uint8(255);
end
