% DIC Postprocess ops helper. Expected caller: dic_postprocess.analysisRun.makeStrainOverlay.
% Inputs are strain map, optional ROI mask, and display mask. Output is logical
% valid strain map. Side effects: none.
function validMap = strainValidMask(strainMap, roiMask, displayMask, edgeTrim)
    if nargin < 4 || isempty(edgeTrim)
        edgeTrim = 1;
    end

    validMap = isfinite(strainMap);
    if ~isempty(roiMask)
        validMap = validMap & logical(roiMask);
    else
        validMap = validMap & dic_postprocess.analysisRun.resizeNearest( ...
            logical(displayMask), size(strainMap));
    end
    validMap = dic_postprocess.analysisRun.trimStrainEdgeMask(validMap, edgeTrim);
end
