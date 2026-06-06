% DIC Postprocess ops helper. Expected caller: dic_postprocess.ops.makeStrainOverlay.
% Inputs are strain map, optional ROI mask, and display mask. Output is logical
% valid strain map. Side effects: none.
function validMap = strainValidMask(strainMap, roiMask, displayMask)
    validMap = isfinite(strainMap);
    if ~isempty(roiMask)
        validMap = validMap & logical(roiMask);
    else
        validMap = validMap & imresize(logical(displayMask), size(strainMap), 'nearest');
    end
end
