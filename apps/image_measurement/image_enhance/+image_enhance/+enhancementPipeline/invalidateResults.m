function applicationState = invalidateResults(applicationState)
%INVALIDATERESULTS Clear export identity after inputs or settings change.
applicationState.project.results.resultManifestPath = "";
end
