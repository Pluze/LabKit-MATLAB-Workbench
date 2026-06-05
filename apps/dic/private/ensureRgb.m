% App-owned DIC helper extracted from labkit_DICPostprocess_app.m. Expected caller: DIC app entrypoints.
% Inputs, outputs, and side effects match the original local helper implementation.
function out = ensureRgb(imageData)
    if ndims(imageData) == 2
        out = repmat(imageData, [1 1 3]);
    else
        out = imageData;
    end
end
