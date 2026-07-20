% App-owned implementation for ecg_print.analysisRun.sanitizeParameters within the ecg_print product workflow.
function parameters = sanitizeParameters(parameters, sampleRate)
%SANITIZEPARAMETERS Normalize ECG analysis controls before calculation.
% Inputs are one App-owned parameter struct and the selected signal sample
% rate. Output preserves the struct while making calculation inputs finite
% and legal. Side effects: none.
parameters.roiStart = finiteNonnegative(parameters.roiStart, 0);
parameters.roiEnd = finiteNonnegative(parameters.roiEnd, 0);
parameters.lowCut = finiteNonnegative(parameters.lowCut, 0.5);
parameters.highCut = finiteNonnegative(parameters.highCut, 40);
parameters.highCut = min(parameters.highCut, ...
    max(parameters.lowCut + eps, 0.45 * sampleRate));
parameters.peakDistance = max(eps, ...
    finiteNonnegative(parameters.peakDistance, 0.28));
parameters.segmentWindow = max(eps, ...
    finiteNonnegative(parameters.segmentWindow, 0.7));
parameters.templateTopN = max(1, round( ...
    finiteNonnegative(parameters.templateTopN, 30)));
parameters.smoothBeats = max(1, round( ...
    finiteNonnegative(parameters.smoothBeats, 15)));
end

function value = finiteNonnegative(value, fallback)
value = double(value);
if isempty(value) || ~isscalar(value) || ~isfinite(value)
    value = fallback;
end
value = max(0, value);
end
