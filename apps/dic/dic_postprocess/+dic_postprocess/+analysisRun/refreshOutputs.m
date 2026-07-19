function applicationState = refreshOutputs( ...
        applicationState, ~, callbackContext)
%REFRESHOUTPUTS Recompute prepared overlays after a display option changes.
cache = applicationState.session.cache;
if ~isfield(cache.strain, "exx") || ...
        isempty(cache.referenceImage) || isempty(cache.maskImage)
    return;
end
if applicationState.project.parameters.colorMax <= ...
        applicationState.project.parameters.colorMin
    callbackContext.appendStatus( ...
        "Option update skipped: Color max must exceed color min.");
    return;
end
try
    [summary, overlayExx, overlayEyy] = ...
        dic_postprocess.analysisRun.prepareOutputs( ...
            cache, applicationState.project.parameters);
    applicationState.project.results.summaryTable = summary;
    applicationState.session.cache.overlayExx = overlayExx;
    applicationState.session.cache.overlayEyy = overlayEyy;
catch exception
    callbackContext.reportError("Option update skipped", exception);
    callbackContext.appendStatus( ...
        "Option update skipped: " + exception.message);
end
end
