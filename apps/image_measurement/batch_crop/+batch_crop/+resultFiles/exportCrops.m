% App-owned implementation for batch_crop.resultFiles.exportCrops within the batch_crop product workflow.
function applicationState = exportCrops(applicationState, callbackContext)
%EXPORTCROPS Write crop files, CSV detail manifest, and result provenance.
tasks = applicationState.project.inputs.items;
if isempty(tasks)
    callbackContext.alert("Load images before exporting crops.", ...
        "No images loaded");
    return
end
if ~all([tasks.centerSet])
    callbackContext.alert( ...
        batch_crop.resultFiles.missingWorkflowItemsText(tasks, "center"), ...
        "Crop centers missing");
    return
end
if strcmpi(applicationState.project.parameters.scaleMode, "Physical") && ...
        ~batch_crop.scaleCalibration.summarize(tasks).allCalibrated
    callbackContext.alert( ...
        batch_crop.resultFiles.missingWorkflowItemsText(tasks, "scale"), ...
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
plan = batch_crop.resultFiles.exportPlan(items, options);
results = applicationState.project.results;
if ~isempty(results.lastExport) && ...
        results.lastExportFingerprint == plan.fingerprint
    callbackContext.log("info", "batch_crop.resultfiles.exportcrops.skipped", ...
        "Crop export is already up to date; skipped duplicate write.");
    return
end
try
    if strlength(options.outputFolder) > 0 && ...
            exist(options.outputFolder, "dir") ~= 7
        mkdir(options.outputFolder);
    end
    payload = batch_crop.resultFiles.writeOutputs(items, options);
    package = resultPackage(applicationState, payload);
    written = callbackContext.writeResultPackage( ...
        options.outputFolder, package);
catch cause
    callbackContext.log("error", "batch_crop.resultfiles.exportcrops.exception", "Export failed", ...
        Category="failure", Audience="developer", Exception=cause);
    callbackContext.alert(cause.message, "Export failed");
    return
end
payload.resultManifestPath = string(written.Value);
applicationState.project.results.lastExport = payload;
applicationState.project.results.lastExportFingerprint = plan.fingerprint;
applicationState.project.results.resultManifestPath = string(written.Value);
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

function package = resultPackage(applicationState, payload)
outputs = cell(1, numel(payload.results) + 1);
for k = 1:numel(payload.results)
    result = payload.results(k);
    [~, name, extension] = fileparts(result.outputPath);
    status = "success";
    if string(result.status) ~= "saved"
        status = "failed";
        extension = formatExtension(applicationState.project.parameters.format);
        name = "crop" + string(k) + "_failed";
    end
    outputs{k} = labkit.app.result.File( ...
        "crop" + string(k), "primary", ...
        string(name) + string(extension), ...
        MediaType=mediaType(extension), Status=status, ...
        Message=string(result.message));
end
[~, name, extension] = fileparts(payload.manifestPath);
outputs{end} = labkit.app.result.File("cropManifest", "manifest", ...
    string(name) + string(extension), MediaType="text/csv");
package = labkit.app.result.Package(Outputs=outputs, ...
    Inputs=struct("sources", applicationState.project.inputs.sources), ...
    Parameters=applicationState.project.parameters, ...
    Summary=struct("taskCount", numel(payload.results), ...
        "savedCount", sum(string({payload.results.status}) == "saved")), ...
    ManifestName="batch_crop_results.labkit.json");
end

function extension = formatExtension(formatValue)
switch upper(string(formatValue))
    case "PNG"
        extension = ".png";
    case {"TIFF", "TIF"}
        extension = ".tif";
    otherwise
        extension = ".jpg";
end
end

function type = mediaType(extension)
switch lower(string(extension))
    case ".png"
        type = "image/png";
    case {".tif", ".tiff"}
        type = "image/tiff";
    otherwise
        type = "image/jpeg";
end
end
