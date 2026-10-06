function applicationState = clearMeasurements(applicationState)
%CLEARMEASUREMENTS Invalidate curve-derived results and export evidence.
applicationState.project.results.fit = ...
    curvature.analysisRun.emptyFitResult();
applicationState.project.results.length = ...
    curvature.analysisRun.emptyLengthResult();

end
