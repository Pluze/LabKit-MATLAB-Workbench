function applicationState = clearMeasurements(applicationState)
%CLEARMEASUREMENTS Invalidate curve-derived results and export evidence.
applicationState.project.results.fit = ...
    curvature.analysisRun.emptyFitResult();
applicationState.project.results.length = ...
    curvature.analysisRun.emptyLengthResult();
applicationState.project.results.lastCsvExport = [];
applicationState.project.results.lastOverlayExport = [];
applicationState.session.cache.fitFingerprint = "";
applicationState.session.cache.lengthFingerprint = "";
end
