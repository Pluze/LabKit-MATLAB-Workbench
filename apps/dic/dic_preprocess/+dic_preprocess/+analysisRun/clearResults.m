% App-owned implementation for dic_preprocess.analysisRun.clearResults within the dic_preprocess product workflow.
function applicationState = clearResults(applicationState)
%CLEARRESULTS Invalidate output manifests after a semantic edit.
applicationState.project.results.currentImagesManifestPath = "";
applicationState.project.results.maskManifestPath = "";
end
