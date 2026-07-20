% App-owned implementation for image_match.matchPipeline.invalidateResults within the image_match product workflow.
function applicationState = invalidateResults(applicationState)
%INVALIDATERESULTS Clear export identity after match inputs change.
applicationState.project.results.lastExport = [];
applicationState.project.results.lastExportFingerprint = "";
applicationState.project.results.resultManifestPath = "";
end
