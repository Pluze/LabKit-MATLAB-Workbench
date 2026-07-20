% App-owned implementation for flir_thermal.displayMapping.changeColorMapping within the flir_thermal product workflow.
function applicationState = changeColorMapping( ...
        applicationState, mapping, callbackContext)
%CHANGECOLORMAPPING Normalize linear, logarithmic, or gamma display mapping.
mapping = string(mapping);
if any(mapping == ["Linear", "Log", "Gamma"])
    applicationState.project.parameters.colorMapping = mapping;
    applicationState = invalidateResults(applicationState);
    callbackContext.appendStatus( ...
        "Thermal color mapping: " + mapping + ".");
end
end

function applicationState = invalidateResults(applicationState)
applicationState.project.results.lastExport = [];
applicationState.project.results.resultManifestPath = "";
end
