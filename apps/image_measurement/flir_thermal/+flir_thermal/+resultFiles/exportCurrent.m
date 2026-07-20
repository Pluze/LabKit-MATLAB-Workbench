function applicationState = exportCurrent( ...
        applicationState, callbackContext)
%EXPORTCURRENT Export the selected FLIR image and its numeric products.
sources = applicationState.project.inputs.sources;
index = applicationState.session.selection.currentIndex;
if isempty(sources) || index < 1 || index > numel(sources)
    callbackContext.alert( ...
        "Load a FLIR radiometric image before exporting.", ...
        "Export unavailable");
    return
end
[payload, manifestPath, ok] = ...
    flir_thermal.resultFiles.writeSelection( ...
        sources(index), applicationState.project.annotations.items, ...
        applicationState.project.parameters, callbackContext);
if ~ok
    return
end
payload.resultManifestPath = manifestPath;
applicationState.project.results.lastExport = payload;
applicationState.project.results.resultManifestPath = manifestPath;
callbackContext.appendStatus( ...
    "Exported current FLIR image: " + payload.manifestPath);
end
