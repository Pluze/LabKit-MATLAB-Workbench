% App-owned DIC helper extracted from labkit_DICPostprocess_app.m. Expected caller: DIC app entrypoints.
% Inputs, outputs, and side effects match the original local helper implementation.
function validMap = strainValidMask(strainMap, roiMask, displayMask)
    validMap = isfinite(strainMap);
    if ~isempty(roiMask)
        validMap = validMap & logical(roiMask);
    else
        validMap = validMap & imresize(logical(displayMask), size(strainMap), 'nearest');
    end
end
