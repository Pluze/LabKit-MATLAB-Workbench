% App-owned DIC helper extracted from labkit_DICPreprocess_app.m. Expected caller: DIC app entrypoints.
% Inputs, outputs, and side effects match the original local helper implementation.
function txt = displayPath(pathValue)
    if strlength(pathValue) == 0
        txt = 'none';
    else
        txt = char(pathValue);
    end
end
