% App-owned DIC helper extracted from labkit_DICPreprocess_app.m. Expected caller: DIC app entrypoints.
% Inputs, outputs, and side effects match the original local helper implementation.
function T = transformMatrix(tform)
    if isprop(tform, 'T')
        T = tform.T;
    elseif isprop(tform, 'A')
        T = tform.A;
    else
        T = eye(3);
    end
end
