% App-owned implementation for ecg_print.analysisRun.sanitizeParameters within the ecg_print product workflow.
function parameters = sanitizeParameters(parameters, sampleRate)
%SANITIZEPARAMETERS Normalize ECG analysis controls before calculation.
% Inputs are one App-owned parameter struct and the selected signal sample
% rate. Output preserves the struct while making calculation inputs finite
% and legal. Side effects: none.
parameters.roiStart = finiteNonnegative(parameters.roiStart, 0);
parameters.roiEnd = finiteNonnegative(parameters.roiEnd, 0);
parameters.lowCut = finiteNonnegative(parameters.lowCut, 0);
parameters.highCut = finiteNonnegative(parameters.highCut, 0.5 * sampleRate);
maximumCutoff = max(eps, 0.5 * double(sampleRate));
[parameters.lowCut, parameters.highCut] = legalBand( ...
    parameters.lowCut, parameters.highCut, maximumCutoff);
parameters.useAnalysisBandForPeaks = logicalValue( ...
    fieldValue(parameters, "useAnalysisBandForPeaks", true), true);
peakLowCut = finiteNonnegative( ...
    fieldValue(parameters, "peakLowCut", parameters.lowCut), ...
    parameters.lowCut);
peakHighCut = finiteNonnegative( ...
    fieldValue(parameters, "peakHighCut", parameters.highCut), ...
    parameters.highCut);
[parameters.peakLowCut, parameters.peakHighCut] = legalBand( ...
    peakLowCut, peakHighCut, maximumCutoff);
parameters.peakDistance = max(eps, ...
    finiteNonnegative(parameters.peakDistance, 0.28));
parameters.segmentWindow = max(eps, ...
    finiteNonnegative(parameters.segmentWindow, 0.7));
parameters.templateTopN = max(1, round( ...
    finiteNonnegative(parameters.templateTopN, 30)));
parameters.smoothBeats = max(1, round( ...
    finiteNonnegative(parameters.smoothBeats, 15)));
end

function [low, high] = legalBand(low, high, maximum)
margin = max(eps(maximum), eps);
low = min(low, max(0, maximum - margin));
high = min(max(high, low + margin), maximum);
end

function value = fieldValue(parameters, name, fallback)
if isfield(parameters, name)
    value = parameters.(name);
else
    value = fallback;
end
end

function value = logicalValue(value, fallback)
if ~(islogical(value) && isscalar(value))
    value = fallback;
end
end

function value = finiteNonnegative(value, fallback)
value = double(value);
if isempty(value) || ~isscalar(value) || ~isfinite(value)
    value = fallback;
end
value = max(0, value);
end
