% App-owned DIC helper extracted from labkit_DICPreprocess_app.m. Expected caller: DIC app entrypoints.
% Inputs, outputs, and side effects match the original local helper implementation.
function txt = ternary(cond, trueText, falseText)
    if cond
        txt = trueText;
    else
        txt = falseText;
    end
end
