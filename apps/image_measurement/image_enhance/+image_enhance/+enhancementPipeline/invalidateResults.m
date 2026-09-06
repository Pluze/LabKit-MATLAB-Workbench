% App-owned implementation for image_enhance.enhancementPipeline.invalidateResults within the image_enhance product workflow.
function applicationState = invalidateResults(applicationState)
%INVALIDATERESULTS Clear export identity after inputs or settings change.
applicationState.project.results.lastExport = [];
applicationState.project.results.resultManifestPath = "";
end
