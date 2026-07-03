% DIC Postprocess ops helper. Expected caller: dic_postprocess.analysisRun.summarizeStrain.
% Input is numeric data. Output is [mean; std; median; min; max] ignoring NaN
% and Inf, or NaNs when empty. Side effects: none.
function values = nanSafeStats(x)
    x = x(:);
    x = x(isfinite(x));
    if isempty(x)
        values = nan(5, 1);
        return;
    end
    values = [mean(x); std(x); median(x); min(x); max(x)];
end
