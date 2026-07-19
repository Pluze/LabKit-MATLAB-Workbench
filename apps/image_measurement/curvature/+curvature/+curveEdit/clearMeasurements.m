function state = clearMeasurements(state)
state.project.results.fit = curvature.analysisRun.emptyFitResult();
state.project.results.length = curvature.analysisRun.emptyLengthResult();
state.session.cache.fitFingerprint = "";
state.session.cache.lengthFingerprint = "";
end
