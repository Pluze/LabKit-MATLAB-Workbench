function state = fit(state, context)
points = state.project.annotations.curvePoints;
if size(points,1) < 3, context.alert("At least 3 curve points are required.", "Not enough points"); return, end
path = curvature.curvePreview.visiblePath(points, state.session.cache.image);
p = state.project.parameters; c = state.project.annotations.calibration;
state.project.results.fit = curvature.analysisRun.computeCurvatureFit( ...
    points(:,1),points(:,2),c,p.densify,p.densePointCount,path(:,1),path(:,2));
state.project.results.length = curvature.analysisRun.lengthResultFromFit(state.project.results.fit);
end
