function applicationState = clearResults(applicationState)
%CLEARRESULTS Invalidate output manifests after a semantic edit.
applicationState.project.results.currentImagesManifestPath = "";
applicationState.project.results.maskManifestPath = "";
end
