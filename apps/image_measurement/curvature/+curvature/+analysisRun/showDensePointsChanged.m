% App-owned implementation for curvature.analysisRun.showDensePointsChanged within the curvature product workflow.
function applicationState = showDensePointsChanged( ...
        applicationState, visible, callbackContext)
%SHOWDENSEPOINTSCHANGED Update presentation-only dense-point visibility.
applicationState.project.parameters.showDensePoints = logical(visible);
callbackContext.appendStatus("Curvature overlay display changed.");
end
