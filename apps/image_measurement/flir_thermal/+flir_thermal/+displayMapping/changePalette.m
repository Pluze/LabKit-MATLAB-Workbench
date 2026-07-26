% App-owned implementation for flir_thermal.displayMapping.changePalette within the flir_thermal product workflow.
function applicationState = changePalette( ...
        applicationState, palette, callbackContext)
%CHANGEPALETTE Normalize the thermal display palette.
palette = lower(string(palette));
if any(palette == ["turbo", "iron", "hot", "parula", "gray"])
    applicationState.project.parameters.palette = palette;
    applicationState = invalidateResults(applicationState);
    callbackContext.log("info", ...
        "flir_thermal.displaymapping.changepalette.status", ...
        "Thermal palette: " + palette + ".");
end
end

function applicationState = invalidateResults(applicationState)
applicationState.project.results.lastExport = [];
applicationState.project.results.resultManifestPath = "";
end
