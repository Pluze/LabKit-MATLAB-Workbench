function state = measureLength(state, context)
points = state.project.annotations.curvePoints;
if size(points,1) < 2, context.alert("At least 2 curve points are required.", "Not enough points"); return, end
path = curvature.curvePreview.visiblePath(points, state.session.cache.image);
state.project.results.length = curvature.analysisRun.computeCurveLength( ...
    path(:,1),path(:,2),state.project.annotations.calibration);
end
