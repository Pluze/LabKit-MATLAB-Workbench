function applicationState = exportImages( ...
        applicationState, callbackContext)
%EXPORTIMAGES Apply committed matches and write CSV and LabKit manifests.
sources = applicationState.project.inputs.sources;
referenceSource = applicationState.project.inputs.reference;
if isempty(referenceSource) || isempty(sources)
    callbackContext.alert( ...
        "Load source and reference images before exporting.", ...
        "Export unavailable");
    return;
end
folder = string(applicationState.project.parameters.outputFolder);
if strlength(folder) == 0
    choice = callbackContext.chooseOutputFolder("");
    if choice.Cancelled
        callbackContext.appendStatus("Image-match export cancelled.");
        return;
    end
    folder = string(choice.Value);
    applicationState.project.parameters.outputFolder = folder;
end
try
    items = image_match.sourceFiles.readImages( ...
        callbackContext.resolveSourcePaths(sources));
    referenceItems = image_match.sourceFiles.readImages( ...
        callbackContext.resolveSourcePaths(referenceSource(1)));
    referenceItem = referenceItems(1);
    options = struct( ...
        "outputFolder", folder, ...
        "format", applicationState.project.parameters.exportFormat);
    task = image_match.resultFiles.exportTask( ...
        items, referenceItem, ...
        applicationState.project.annotations.steps, options);
    if ~isempty(applicationState.project.results.lastExport) && ...
            applicationState.project.results.lastExportFingerprint == ...
            task.fingerprint
        callbackContext.appendStatus( ...
            "Matched export is already up to date.");
        return;
    end
    payload = image_match.resultFiles.writeOutputs( ...
        items, referenceItem, ...
        applicationState.project.annotations.steps, options);
    package = labkit.app.result.Package( ...
        Outputs=packageOutputs(payload), ...
        Inputs=struct( ...
            "reference", referenceSource, "sources", sources), ...
        Parameters=applicationState.project.parameters, ...
        Summary=struct("imageCount", numel(items)), ...
        ManifestName="image_match.labkit.json");
    written = callbackContext.writeResultPackage(folder, package);
catch ME
    callbackContext.reportError("Export matched images", ME);
    callbackContext.alert(ME.message, "Export failed");
    callbackContext.appendStatus( ...
        "Image-match export failed: " + string(ME.message));
    return;
end
payload.sourceIds = string({sources.id});
payload.referenceId = string(referenceSource(1).id);
payload.resultManifestPath = string(written.Value);
applicationState.project.results.lastExport = payload;
applicationState.project.results.lastExportFingerprint = task.fingerprint;
applicationState.project.results.resultManifestPath = string(written.Value);
callbackContext.appendStatus( ...
    "Exported matched images: " + payload.manifestPath);
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
        "matched_" + compose("%03d", index), ...
        "matched-image", string(name) + string(extension), ...
        MediaType=mediaType(extension), Status=status, ...
        Message=result.message);
end
[~, name, extension] = fileparts(payload.manifestPath);
outputs{end} = labkit.app.result.File( ...
    "batch_manifest", "batch-summary", ...
    string(name) + string(extension), MediaType="text/csv");
end

function value = mediaType(extension)
if any(lower(string(extension)) == [".jpg" ".jpeg"])
    value = "image/jpeg";
elseif any(lower(string(extension)) == [".tif" ".tiff"])
    value = "image/tiff";
else
    value = "image/png";
end
end
