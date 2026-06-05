% App-owned DIC helper extracted from labkit_DICPostprocess_app.m. Expected caller: DIC app entrypoints.
% Inputs, outputs, and side effects match the original local helper implementation.
function values = nanSafeStats(x)
    x = x(:);
    x = x(isfinite(x));
    if isempty(x)
        values = nan(5, 1);
        return;
    end
    values = [mean(x); std(x); median(x); min(x); max(x)];
end
