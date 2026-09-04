% App-owned implementation for ecg_print.analysisRun.present within the ecg_print product workflow.
function view = present(cache, parameters, ~, hasSignal)
choices = string(cache.channelItems);
value = string(parameters.channel);
if ~any(value == choices), value = choices(1); end
view = labkit.app.view.Snapshot() ...
    .choices("channel", choices).value("channel", value) ...
    .enabled("channel", hasSignal).enabled("analyze", hasSignal);
cutoffLimit = 10000;
if hasSignal
    cutoffLimit = max(eps, 0.5 * double(cache.signal.fs));
end
cutoffLimits = [0 cutoffLimit];
useAnalysisBand = true;
if isfield(parameters, "useAnalysisBandForPeaks")
    useAnalysisBand = parameters.useAnalysisBandForPeaks;
end
view = view.limits("lowCut", cutoffLimits) ...
    .limits("highCut", cutoffLimits) ...
    .limits("peakLowCut", cutoffLimits) ...
    .limits("peakHighCut", cutoffLimits) ...
    .enabled("peakLowCut", hasSignal && ~useAnalysisBand) ...
    .enabled("peakHighCut", hasSignal && ~useAnalysisBand);
end
