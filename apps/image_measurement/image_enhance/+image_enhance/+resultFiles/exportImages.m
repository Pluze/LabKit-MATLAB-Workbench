% App-owned implementation for image_enhance.resultFiles.exportImages within the image_enhance product workflow.
function applicationState = exportImages( ...
        applicationState, callbackContext)
%EXPORTIMAGES Render every source and write CSV and LabKit manifests.
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
        callbackContext.resolveSourcePaths(sources));
    [items, steps, itemSteps] = exportSteps( ...
        applicationState, items);
    options = struct( ...
        "outputFolder", folder, ...
        "format", applicationState.project.parameters.exportFormat, ...
        "itemSteps", {itemSteps});
    task = image_enhance.resultFiles.exportTask( ...
        items, steps, options);
    if ~isempty(applicationState.project.results.lastExport) && ...
            applicationState.project.results.lastExportFingerprint == ...
            task.fingerprint
        callbackContext.log("info", ...
            "image_enhance.resultfiles.exportimages.skipped", ...
            "Enhanced export is already up to date.");
        return;
    end
    payload = image_enhance.resultFiles.writeOutputs( ...
        items, steps, options);
    package = labkit.app.result.Package( ...
        Outputs=packageOutputs(payload), ...
        Inputs=struct("sources", sources), ...
        Parameters=applicationState.project.parameters, ...
        Summary=struct( ...
            "imageCount", numel(items), ...
            "savedCount", sum( ...
                string({payload.results.status}) == "saved")), ...
        ManifestName="image_enhance.labkit.json");
    written = callbackContext.writeResultPackage(folder, package);
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
payload.resultManifestPath = string(written.Value);
applicationState.project.results.lastExport = payload;
applicationState.project.results.lastExportFingerprint = task.fingerprint;
applicationState.project.results.resultManifestPath = string(written.Value);
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

function outputs = packageOutputs(payload)
outputs = cell(1, numel(payload.results) + 1);
for index = 1:numel(payload.results)
    result = payload.results(index);
    [~, name, extension] = fileparts(result.outputPath);
    status = "failed";
    if result.status == "saved"
        status = "success";
    end
    outputs{index} = labkit.app.result.File( ...
        "enhanced_" + compose("%03d", index), ...
        "enhanced-image", string(name) + string(extension), ...
        MediaType=mediaType(extension), Status=status, ...
        Message=result.message);
end
[~, name, extension] = fileparts(payload.manifestPath);
outputs{end} = labkit.app.result.File( ...
    "batch_manifest", "batch-summary", ...
    string(name) + string(extension), MediaType="text/csv");
end

function value = mediaType(extension)
switch lower(string(extension))
    case {".jpg", ".jpeg"}
        value = "image/jpeg";
    case {".tif", ".tiff"}
        value = "image/tiff";
    otherwise
        value = "image/png";
end
end
