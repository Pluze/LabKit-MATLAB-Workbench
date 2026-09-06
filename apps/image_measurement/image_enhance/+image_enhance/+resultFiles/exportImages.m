% App-owned implementation for image_enhance.resultFiles.exportImages within the image_enhance product workflow.
function applicationState = exportImages( ...
        applicationState, callbackContext)
%EXPORTIMAGES Render every source and write the App-owned CSV manifest.
sources = applicationState.project.inputs.sources;
if isempty(sources)
    callbackContext.alert( ...
        "Load images before exporting.", "No images loaded");
    return;
end
folder = string(applicationState.project.parameters.outputFolder);
if strlength(folder) == 0
    choice = callbackContext.chooseOutputFolder("");
    if choice.Cancelled
        callbackContext.log("info", ...
            "image_enhance.resultfiles.exportimages.cancelled", ...
            "Image export cancelled.");
        return;
    end
    folder = string(choice.Value);
    applicationState.project.parameters.outputFolder = folder;
end
try
    items = image_enhance.sourceFiles.readImages( ...
        labkit.app.source.paths(sources));
    [items, steps, itemSteps] = exportSteps( ...
        applicationState, items);
    options = struct( ...
        "outputFolder", folder, ...
        "format", applicationState.project.parameters.exportFormat, ...
        "itemSteps", {itemSteps});
    payload = image_enhance.resultFiles.writeOutputs( ...
        items, steps, options);
catch ME
    callbackContext.log("error", "image_enhance.resultfiles.exportimages.exception", "Export enhanced images", ...
        Category="failure", Audience="developer", Exception=ME);
    callbackContext.alert(ME.message, "Export failed");
    callbackContext.log("error", ...
        "image_enhance.resultfiles.exportimages.failed", ...
        "Image export failed.");
    return;
end
payload.sourceIds = string({sources.id});
payload.resultManifestPath = payload.manifestPath;
applicationState.project.results.lastExport = payload;
applicationState.project.results.resultManifestPath = payload.manifestPath;
statuses = string({payload.results.status});
failedCount = sum(statuses == "failed");
severity = "info";
if failedCount > 0
    severity = "warning";
end
callbackContext.log(severity, ...
    "image_enhance.resultfiles.exportimages.completed", ...
    sprintf("Exported %d image(s); %d failed.", ...
    sum(statuses == "saved"), failedCount));
end

function [items, steps, itemSteps] = exportSteps( ...
        applicationState, items)
if applicationState.project.parameters.batchMode
    steps = applicationState.project.annotations.sharedSteps;
    itemSteps = {};
    return;
end
steps = repmat(image_enhance.analysisRun.emptyStep(), 0, 1);
itemSteps = cell(numel(items), 1);
for index = 1:numel(items)
    sourceId = applicationState.project.inputs.sources(index).id;
    annotation = image_enhance.sourceLibrary.annotationForSource( ...
        applicationState.project.annotations.items, sourceId);
    itemSteps{index} = annotation.steps;
    items(index).whiteRoi = annotation.whiteRoi;
end
end
