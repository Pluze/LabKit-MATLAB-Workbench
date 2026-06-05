% App-owned DIC helper extracted from labkit_DICPostprocess_app.m. Expected caller: DIC app entrypoints.
% Inputs, outputs, and side effects match the original local helper implementation.
function targetSize = imageHeightWidth(imageData)
    targetSize = [size(imageData, 1), size(imageData, 2)];
end
