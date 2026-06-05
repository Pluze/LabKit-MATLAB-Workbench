% App-owned DIC helper extracted from labkit_DICPreprocess_app.m. Expected caller: DIC app entrypoints.
% Inputs, outputs, and side effects match the original local helper implementation.
function rgb = maskRgb(maskImage)
    rgb = repmat(maskImage, [1 1 3]);
end
