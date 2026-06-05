% App-owned DIC helper extracted from labkit_DICPreprocess_app.m. Expected caller: DIC app entrypoints.
% Inputs, outputs, and side effects match the original local helper implementation.
function deleteIfValid(h)
    if isempty(h)
        return;
    end
    if isvalid(h)
        delete(h);
    end
end
