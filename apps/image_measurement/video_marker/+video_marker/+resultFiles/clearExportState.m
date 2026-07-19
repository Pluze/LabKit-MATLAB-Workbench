function state = clearExportState(state)
%CLEAREXPORTSTATE Invalidate result manifests after an annotation change.
state.project.results.markerManifestPath = "";
state.project.results.coordinateManifestPath = "";
end
