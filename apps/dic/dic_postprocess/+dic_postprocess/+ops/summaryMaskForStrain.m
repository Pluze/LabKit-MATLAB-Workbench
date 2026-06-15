% DIC Postprocess ops helper. Expected caller: labkit_DICPostprocess_app.
% Input is the MAT-derived strain struct. Output is the logical summary mask
% over the MAT strain domain. Side effects: none.
function mask = summaryMaskForStrain(strain)
    mask = isfinite(strain.exx) | isfinite(strain.eyy);
    if ~isempty(strain.roiMask)
        mask = mask & logical(strain.roiMask);
    end
end
