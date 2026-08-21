% App-owned implementation for focus_stack.resultFiles.exportResult within the focus_stack product workflow.
function applicationState = exportResult( ...
        applicationState, kind, callbackContext)
%EXPORTRESULT Write one App-owned Focus Stack output.
result = applicationState.session.cache.result;
if ~result.ok
    callbackContext.alert( ...
        "Run focus stack before exporting results.", "No result");
    return;
end
[defaultName, filters] = outputContract(kind);
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
    folder = string(fileparts(filepath));
catch ME
    callbackContext.log("error", "focus_stack.resultfiles.exportresult.exception", "Export Focus Stack result", ...
        Category="failure", Audience="developer", Exception=ME);
    callbackContext.alert(ME.message, "Could not export result");
    callbackContext.log("error", ...
        "focus_stack.resultfiles.exportresult.failed", ...
        "Could not export the Focus Stack result.");
    return;
end
applicationState.project.parameters.outputFolder = string(folder);
applicationState.project.results.lastExport = struct( ...
    "kind", kind, "outputPath", filepath);
applicationState.project.results.lastOutputPath = filepath;
callbackContext.log("info", ...
    "focus_stack.resultfiles.exportresult.completed", ...
    "Exported the selected Focus Stack result.");
end

function [name, filters] = outputContract(kind)
switch string(kind)
    case "fused"
        name = "focus_stack_fused.png";
        filters = ["*.png", "PNG image (*.png)"];
    case "focus-map"
        name = "focus_stack_map.png";
        filters = ["*.png", "PNG image (*.png)"];
    case "summary"
        name = "focus_stack_summary.csv";
        filters = ["*.csv", "CSV files (*.csv)"];
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
