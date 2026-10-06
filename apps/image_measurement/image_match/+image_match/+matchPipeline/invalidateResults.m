function applicationState = invalidateResults(applicationState)
%INVALIDATERESULTS Clear export identity after match inputs change.
applicationState.project.results.resultManifestPath = "";
end
