% DIC Postprocess ops helper. Expected caller: dic_postprocess.ops.strainToRgb.
% Inputs are a strain map and valid map. Output fills invalid ROI pixels from
% nearest valid strain samples. Side effects: none.
function Sfilled = extendStrainMapToRoi(S, validMap)
    validMap = logical(validMap) & isfinite(S);
    Sfilled = S;
    if ~any(validMap(:))
        Sfilled(:) = NaN;
        return;
    end

    invalid = ~validMap;
    if ~any(invalid(:))
        return;
    end
    [~, nearestIdx] = bwdist(validMap);
    Sfilled(invalid) = S(nearestIdx(invalid));
end
