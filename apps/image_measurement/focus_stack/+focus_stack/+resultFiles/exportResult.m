% App-owned implementation for focus_stack.resultFiles.exportResult within the focus_stack product workflow.
function applicationState = exportResult( ...
        applicationState, kind, callbackContext)
%EXPORTRESULT Write one Focus Stack output and its standard result manifest.
result = applicationState.session.cache.result;
if ~result.ok
    callbackContext.alert( ...
        "Run focus stack before exporting results.", "No result");
    return;
end
[defaultName, filters, mediaType] = outputContract(kind);
defaultPath = fullfile(defaultFolder(applicationState), defaultName);
choice = callbackContext.chooseOutputFile(filters, defaultPath);
if choice.Cancelled
    callbackContext.log("info", ...
        "focus_stack.resultfiles.exportresult.cancelled", ...
        "Export " + kind + " cancelled.");
    return;
end
filepath = string(choice.Value);
try
    writeOutput(kind, result, ...
        applicationState.session.cache.sourcePaths, filepath);
    [folder, name, extension] = fileparts(filepath);
    relativePath = string(name) + string(extension);
    output = labkit.app.result.File( ...
        replace(kind, "-", "_"), kind, relativePath, ...
        MediaType=mediaType);
    package = labkit.app.result.Package( ...
        Outputs={output}, ...
        Inputs=struct( ...
            "sources", applicationState.project.inputs.sources), ...
        Parameters=applicationState.project.parameters, ...
        Summary=applicationState.project.results.lastRun, ...
        ManifestName="focus_stack.labkit.json");
    written = callbackContext.writeResultPackage(folder, package);
catch ME
    callbackContext.reportError("Export Focus Stack result", ME);
    callbackContext.alert(ME.message, "Could not export result");
    callbackContext.log("error", ...
        "focus_stack.resultfiles.exportresult.failed", ...
        "Could not export the Focus Stack result.");
    return;
end
applicationState.project.parameters.outputFolder = string(folder);
applicationState.project.results.lastExport = struct( ...
    "kind", kind, "outputPath", filepath, ...
    "manifestPath", string(written.Value));
applicationState.project.results.resultManifestPath = string(written.Value);
callbackContext.log("info", ...
    "focus_stack.resultfiles.exportresult.completed", ...
    "Exported the selected Focus Stack result.");
end

function [name, filters, mediaType] = outputContract(kind)
switch string(kind)
    case "fused"
        name = "focus_stack_fused.png";
        filters = ["*.png", "PNG image (*.png)"];
        mediaType = "image/png";
    case "focus-map"
        name = "focus_stack_map.png";
        filters = ["*.png", "PNG image (*.png)"];
        mediaType = "image/png";
    case "summary"
        name = "focus_stack_summary.csv";
        filters = ["*.csv", "CSV files (*.csv)"];
        mediaType = "text/csv";
    otherwise
        error("labkit_FocusStack_app:UnknownExport", ...
            "Unknown Focus Stack export kind: %s.", kind);
end
end

function writeOutput(kind, result, paths, filepath)
switch string(kind)
    case "fused"
        labkit.image.writeFile(result.fused, filepath);
    case "focus-map"
        imageData = focus_stack.focusPreview.focusIndexRgb( ...
            result.focusIndex, result.inputCount);
        labkit.image.writeFile(imageData, filepath);
    case "summary"
        writetable(focus_stack.resultFiles.buildSummaryTable( ...
            result, paths), filepath);
end
end

function folder = defaultFolder(applicationState)
folder = string(applicationState.project.parameters.outputFolder);
if strlength(folder) > 0 && isfolder(folder)
    return;
end
paths = applicationState.session.cache.sourcePaths;
if ~isempty(paths)
    candidate = string(fileparts(paths(1)));
    if isfolder(candidate)
        folder = candidate;
        return;
    end
end
folder = string(pwd);
end
