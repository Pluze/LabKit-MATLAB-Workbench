% App-owned DIC helper extracted from labkit_DICPostprocess_app.m. Expected caller: DIC app entrypoints.
% Inputs, outputs, and side effects match the original local helper implementation.
function Sfilled = extendStrainMapToRoi(S, validMap)
    validMap = logical(validMap) & isfinite(S);
    Sfilled = S;
    if ~any(validMap(:))
        Sfilled(:) = NaN;
        return;
    end

    [~, nearestIdx] = bwdist(validMap);
    invalid = ~validMap;
    Sfilled(invalid) = S(nearestIdx(invalid));
end
