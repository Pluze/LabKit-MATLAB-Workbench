%EMPTYRESULT Empty gait analysis result payload.
% Expected caller: initial state, reset paths, and failed imports.
function result = emptyResult()
    result = struct();
    result.ok = false;
    result.message = "No analysis run";
    result.frameTable = table();
    result.stepTable = table();
    result.summaryTable = table('Size', [0 2], ...
        'VariableTypes', {'string', 'string'}, ...
        'VariableNames', {'Metric', 'Value'});
    result.events = struct("liftOffFrames", [], "landingFrames", [], ...
        "detectionSignal", [], "footRelativeX", [], "prominence", [], ...
        "minimumPeakHeight", NaN);
    result.options = gait_analysis.appState.defaultOptions();
end
