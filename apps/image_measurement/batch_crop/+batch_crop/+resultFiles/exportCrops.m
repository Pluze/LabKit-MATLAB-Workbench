% App-owned implementation for batch_crop.resultFiles.exportCrops within the batch_crop product workflow.
function applicationState = exportCrops(applicationState, callbackContext)
%EXPORTCROPS Write crop files and the App-owned CSV detail manifest.
tasks = applicationState.project.inputs.items;
if isempty(tasks)
    callbackContext.alert("Load images before exporting crops.", ...
        "No images loaded");
    return
end
displayItems = batch_crop.sourceFiles.workingItems(tasks, ...
    applicationState.session.cache.images, ...
    applicationState.session.cache.paths);
if ~all([tasks.centerSet])
    callbackContext.alert( ...
        batch_crop.resultFiles.missingWorkflowItemsText(displayItems, "center"), ...
        "Crop centers missing");
    return
end
if strcmpi(applicationState.project.parameters.scaleMode, "Physical") && ...
        ~batch_crop.scaleCalibration.summarize(tasks).allCalibrated
    callbackContext.alert( ...
        batch_crop.resultFiles.missingWorkflowItemsText(displayItems, "scale"), ...
        "Scale calibration missing");
    return
end
try
    items = batch_crop.sourceFiles.workingItems(tasks, ...
        applicationState.session.cache.images, ...
        applicationState.session.cache.paths);
    items = batch_crop.sourceFiles.loadMissingImages(items);
catch cause
    callbackContext.log("error", "batch_crop.resultfiles.exportcrops.exception", "Could not load image", ...
        Category="failure", Audience="developer", Exception=cause);
    callbackContext.alert(cause.message, "Could not load image");
    return
end
applicationState.session.cache.images = {items.image}.';
applicationState.session.cache.canvas = ...
    batch_crop.cropGeometry.emptyCanvasCache();
options = batch_crop.resultFiles.currentOptions(applicationState);
try
    if strlength(options.outputFolder) > 0 && ...
            exist(options.outputFolder, "dir") ~= 7
        mkdir(options.outputFolder);
    end
    payload = batch_crop.resultFiles.writeOutputs(items, options);
catch cause
    callbackContext.log("error", "batch_crop.resultfiles.exportcrops.exception", "Export failed", ...
        Category="failure", Audience="developer", Exception=cause);
    callbackContext.alert(cause.message, "Export failed");
    return
end
payload.resultManifestPath = payload.manifestPath;
applicationState.project.results.lastExport = payload;
applicationState.project.results.resultManifestPath = payload.manifestPath;
statuses = string({payload.results.status});
savedCount = sum(statuses == "saved");
failedCount = sum(statuses == "failed");
severity = "info";
if failedCount > 0
    severity = "warning";
end
callbackContext.log(severity, "batch_crop.resultfiles.exportcrops.completed", ...
    sprintf("Exported %d crop(s); %d failed.", savedCount, failedCount));
if failedCount > 0
    callbackContext.alert( ...
        string(failedCount) + ...
        " image(s) failed. See the manifest for details.", ...
        "Some crops failed");
end
end
