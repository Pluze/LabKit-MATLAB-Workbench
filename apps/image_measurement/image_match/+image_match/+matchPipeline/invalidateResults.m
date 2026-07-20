function applicationState = invalidateResults(applicationState)
%INVALIDATERESULTS Clear export identity after match inputs change.
applicationState.project.results.lastExport = [];
applicationState.project.results.lastExportFingerprint = "";
applicationState.project.results.resultManifestPath = "";
end
