% App-owned implementation for curvature.analysisRun.densifyChanged within the curvature product workflow.
function applicationState = densifyChanged( ...
        applicationState, enabled, callbackContext)
%DENSIFYCHANGED Normalize the fit sampling mode and invalidate results.
applicationState.project.parameters.densify = logical(enabled);
applicationState = curvature.curveEdit.clearMeasurements(applicationState);
callbackContext.appendStatus("Curvature fit settings changed.");
end
