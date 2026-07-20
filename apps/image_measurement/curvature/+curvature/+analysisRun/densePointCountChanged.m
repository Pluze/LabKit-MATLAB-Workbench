% App-owned implementation for curvature.analysisRun.densePointCountChanged within the curvature product workflow.
function applicationState = densePointCountChanged( ...
        applicationState, pointCount, callbackContext)
%DENSEPOINTCOUNTCHANGED Normalize fit sampling density and invalidate results.
pointCount = double(pointCount);
if ~isscalar(pointCount) || ~isfinite(pointCount)
    pointCount = 300;
end
applicationState.project.parameters.densePointCount = ...
    max(3, round(pointCount));
applicationState = curvature.curveEdit.clearMeasurements(applicationState);
callbackContext.appendStatus("Curvature fit settings changed.");
end
