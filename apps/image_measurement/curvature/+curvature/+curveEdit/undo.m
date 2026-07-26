% App-owned implementation for curvature.curveEdit.undo within the curvature product workflow.
function applicationState = undo(applicationState, callbackContext)
%UNDO Remove the newest curve anchor and invalidate measurements.
points = applicationState.project.annotations.curvePoints;
if isempty(points)
    return
end
points(end, :) = [];
applicationState.project.annotations.curvePoints = points;
applicationState = curvature.curveEdit.clearMeasurements(applicationState);
callbackContext.log("info", "curvature.curveedit.undo.status", ...
    "Undid last curve point.");
end
