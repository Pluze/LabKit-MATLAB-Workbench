% DIC Postprocess ops helper. Expected caller: labkit_DICPostprocess_app.
% Inputs are strain struct and overlay mask. Output is logical summary mask.
% Side effects: none.
function mask = summaryMaskForStrain(strain, overlayMask)
    if ~isempty(strain.roiMask)
        mask = logical(strain.roiMask);
    else
        mask = imresize(logical(overlayMask), size(strain.exx), 'nearest');
    end
end
