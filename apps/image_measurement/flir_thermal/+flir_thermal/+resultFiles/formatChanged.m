% App-owned implementation for flir_thermal.resultFiles.formatChanged within the flir_thermal product workflow.
function applicationState = formatChanged( ...
        applicationState, formatName, callbackContext)
%FORMATCHANGED Normalize the rendered thermal-image export format.
formatName = upper(string(formatName));
if any(formatName == ["PNG", "TIFF", "JPEG"])
    applicationState.project.parameters.exportFormat = formatName;
    applicationState.project.results.lastExport = [];
    applicationState.project.results.resultManifestPath = "";
    callbackContext.log("info", ...
        "flir_thermal.resultfiles.formatchanged.status", ...
        "FLIR export image format: " + formatName + ".");
end
end
