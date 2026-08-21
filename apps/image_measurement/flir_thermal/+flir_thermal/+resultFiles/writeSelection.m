% App-owned implementation for flir_thermal.resultFiles.writeSelection within the flir_thermal product workflow.
function [payload, manifestPath, ok] = writeSelection( ...
        sources, annotations, parameters, callbackContext)
%WRITESELECTION Decode and export one App-owned FLIR result set.
payload = [];
manifestPath = "";
ok = false;
folder = string(parameters.outputFolder);
if strlength(folder) == 0
    callbackContext.alert( ...
        "Choose an output folder before exporting.", ...
        "Output folder required");
    return
end
try
    paths = callbackContext.resolveSourcePaths(sources);
    items = flir_thermal.sourceFiles.readImages( ...
        paths, struct("SkipInvalid", false));
    items = applyAnnotations(items, sources, annotations);
    options = struct( ...
        "outputFolder", folder, ...
        "format", parameters.exportFormat, ...
        "palette", parameters.palette, ...
        "colorMapping", parameters.colorMapping, ...
        "gammaValue", parameters.gammaValue, ...
        "range", []);
    payload = flir_thermal.resultFiles.writeOutputs(items, options);
catch ME
    callbackContext.log("error", "flir_thermal.resultfiles.writeselection.exception", "Export FLIR thermal results", ...
        Category="failure", Audience="developer", Exception=ME);
    callbackContext.alert(ME.message, "Could not export FLIR images");
    return
end
manifestPath = payload.manifestPath;
ok = true;
end

function items = applyAnnotations(items, sources, annotations)
for k = 1:numel(items)
    match = find(string({annotations.sourceId}) == ...
        string(sources(k).id), 1);
    if ~isempty(match)
        items(k) = flir_thermal.thermalAnnotations.apply( ...
            items(k), annotations(match));
    end
end
end
