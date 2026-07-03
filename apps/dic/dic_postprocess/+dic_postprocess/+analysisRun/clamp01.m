% DIC Postprocess analysis helper. Expected caller: dic_postprocess.analysisRun helpers.
% Input is numeric image data. Output is clamped to [0, 1]. Side effects: none.
function x = clamp01(x)
    x = min(max(x, 0), 1);
end
