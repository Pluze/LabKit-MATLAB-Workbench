% App-owned DIC helper extracted from labkit_DICPostprocess_app.m. Expected caller: DIC app entrypoints.
% Inputs, outputs, and side effects match the original local helper implementation.
function mask = summaryMaskForStrain(strain, overlayMask)
    if ~isempty(strain.roiMask)
        mask = logical(strain.roiMask);
    else
        mask = imresize(logical(overlayMask), size(strain.exx), 'nearest');
    end
end
