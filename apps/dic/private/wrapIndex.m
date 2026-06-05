% App-owned DIC helper extracted from labkit_DICPreprocess_app.m. Expected caller: DIC app entrypoints.
% Inputs, outputs, and side effects match the original local helper implementation.
function idx = wrapIndex(idx, n)
    idx = mod(idx - 1, n) + 1;
end
