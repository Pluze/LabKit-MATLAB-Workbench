% App-owned DIC helper extracted from labkit_DICPreprocess_app.m. Expected caller: DIC app entrypoints.
% Inputs, outputs, and side effects match the original local helper implementation.
function mask = boundaryMaskImage(points, imageSize, boundaryStyle)
    curve = maskBoundaryCurve(points, imageSize, boundaryStyle);
    mask = maskFromCurve(curve, imageSize);
end
