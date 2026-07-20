% App-owned implementation for curvature.curveEdit.change within the curvature product workflow.
function applicationState = change( ...
        applicationState, points, callbackContext)
%CHANGE Commit one managed curve-anchor edit.
points = normalizePoints(points);
applicationState.project.annotations.curvePoints = points;
applicationState = curvature.curveEdit.clearMeasurements(applicationState);
callbackContext.appendStatus( ...
    "Curve edit updated: " + string(size(points, 1)) + " point(s).");
end

function points = normalizePoints(points)
if isempty(points)
    points = zeros(0, 2);
    return
end
points = double(points);
if size(points, 2) ~= 2 || any(~isfinite(points), "all")
    points = zeros(0, 2);
end
end
