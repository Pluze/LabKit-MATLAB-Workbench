function applicationState = zoomToRoi( ...
        applicationState, callbackContext)
%ZOOMTOROI Make the current ROI the lazily decoded preview window.
parameters = applicationState.project.parameters;
context = rhs_preview.analysisRun.previewContext( ...
    applicationState.session, parameters);
if ~rhs_preview.analysisRun.hasValidRoi(context)
    applicationState.session.workflow.statusMessage = ...
        "Drag a preview ROI before using Zoom to ROI.";
    return;
end
roi = sort(double(context.roiSec(:))).';
bounds = rhs_preview.analysisRun.previewWindowBounds(context);
context.windowDurationSec = max(diff(roi), bounds.minDurationSec);
if bounds.hasIndexedDuration
    context.windowDurationSec = min( ...
        context.windowDurationSec, bounds.durationSec);
end
context.windowStartSec = roi(1);
applicationState.session = rhs_preview.analysisRun.applyPreviewContext( ...
    applicationState.session, context);
applicationState.session.view.autoWindow = false;
[applicationState.session, ~, message] = ...
    rhs_preview.analysisRun.readCurrentPreview( ...
        applicationState.session, parameters, ...
        "Zoom to ROI window", true);
if strlength(message) > 0
    callbackContext.appendStatus(message);
end
end
