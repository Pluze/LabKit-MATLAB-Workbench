% Expected caller: batch_crop.definitionActions. Output owns export settings,
% output-folder choice, crop writes, and standard result-manifest state.
function actions = definitionActions()
    actions = struct( ...
        "exportSettingChanged", @onExportSettingChanged, ...
        "chooseOutputFolder", @onChooseOutputFolder, ...
        "exportCrops", @onExportCrops);
end

function state = onExportSettingChanged(state, ~, ~)
    state.project.results = batch_crop.appState.clearExportState( ...
        state.project.results);
end

function state = onChooseOutputFolder(state, ~, services)
    [folder, cancelled] = services.dialogs.outputFolder( ...
        'Select crop export folder', ...
        state.project.parameters.outputFolder);
    if cancelled
        state = services.workflow.log(state, "Export folder selection cancelled.");
        return;
    end
    state.project.parameters.outputFolder = string(folder);
    state.project.results = batch_crop.appState.clearExportState( ...
        state.project.results);
end

function state = onExportCrops(state, ~, services)
    tasks = state.project.inputs.items;
    if isempty(tasks)
        services.dialogs.alert( ...
            'Load images before exporting crops.', 'No images loaded');
        return;
    end
    if ~all([tasks.centerSet])
        services.dialogs.alert( ...
            batch_crop.userInterface.missingWorkflowItemsText(tasks, "center"), ...
            'Crop centers missing');
        return;
    end
    if strcmpi(state.project.parameters.scaleMode, "Physical") && ...
            ~batch_crop.appState.scaleCalibrationSummary(tasks).allCalibrated
        services.dialogs.alert( ...
            batch_crop.userInterface.missingWorkflowItemsText(tasks, "scale"), ...
            'Scale calibration missing');
        return;
    end
    try
        items = batch_crop.appState.workingItems( ...
            tasks, state.session.cache.images, state.project.inputs.sources);
        items = batch_crop.appState.loadMissingImages(items);
    catch ME
        services.diagnostics.report('Could not load image', ME);
        services.dialogs.alert(ME.message, 'Could not load image');
        return;
    end
    state.session.cache.images = {items.image}.';
    state.session.cache.canvas = batch_crop.appState.emptyCanvasCache();
    opts = currentExportOptions(state);
    plan = batch_crop.appState.exportPlan(items, opts);
    results = state.project.results;
    if ~isempty(results.lastExport) && ...
            results.lastExportFingerprint == plan.fingerprint
        state = services.workflow.log(state, ...
            "Crop export is already up to date; skipped duplicate write.");
        return;
    end
    try
        payload = batch_crop.resultFiles.writeOutputs(items, opts);
        spec = standardResultSpec(state, payload, services);
        [manifestPath, ~] = services.results.writeManifest( ...
            opts.outputFolder, spec);
    catch ME
        services.diagnostics.report('Export failed', ME);
        services.dialogs.alert(ME.message, 'Export failed');
        return;
    end
    payload.resultManifestPath = string(manifestPath);
    state.project.results.lastExport = payload;
    state.project.results.lastExportFingerprint = plan.fingerprint;
    state.project.results.resultManifestPath = string(manifestPath);
    statuses = string({payload.results.status});
    savedCount = sum(statuses == "saved");
    failedCount = sum(statuses == "failed");
    state = services.workflow.log(state, sprintf( ...
        'Exported %d crop(s), %d failed. Manifest: %s', ...
        savedCount, failedCount, char(payload.manifestPath)));
    if failedCount > 0
        services.dialogs.alert(sprintf( ...
            '%d image(s) failed. See the manifest for details.', failedCount), ...
            'Some crops failed');
    end
end

function opts = currentExportOptions(state)
    parameters = state.project.parameters;
    padding = 0;
    index = max(0, round(double(state.session.selection.currentIndex)));
    if index >= 1 && index <= numel(state.project.inputs.items) && ...
            index <= numel(state.session.cache.images) && ...
            ~isempty(state.session.cache.images{index})
        padding = state.project.inputs.items(index).paddingPercent;
    end
    opts = batch_crop.appState.exportOptions( ...
        parameters.outputFolder, parameters.format, ...
        batch_crop.appState.currentCropSize(state), padding, ...
        parameters.scaleMode, parameters.scaleUnit, ...
        [parameters.physicalWidth, parameters.physicalHeight], ...
        parameters.targetPixelsPerUnit, parameters.maxUpsamplePercent);
end

function spec = standardResultSpec(state, payload, services)
    cropOutputs = repmat(services.results.output("", "", "", ""), ...
        numel(payload.results), 1);
    for k = 1:numel(payload.results)
        result = payload.results(k);
        [~, name, extension] = fileparts(result.outputPath);
        status = "success";
        if string(result.status) ~= "saved"
            status = "failed";
            extension = formatExtension(state.project.parameters.format);
            name = "crop" + string(k) + "_failed";
        end
        cropOutputs(k) = services.results.output( ...
            "crop" + string(k), "primary", ...
            string(name) + string(extension), mediaType(extension), status, ...
            string(result.message));
    end
    [~, csvName, csvExtension] = fileparts(payload.manifestPath);
    csvOutput = services.results.output("cropManifest", "manifest", ...
        string(csvName) + string(csvExtension), "text/csv");
    spec = struct();
    spec.Outputs = [cropOutputs; csvOutput];
    spec.Inputs = state.project.inputs.sources;
    spec.Parameters = state.project.parameters;
    spec.Summary = struct("taskCount", numel(payload.results), ...
        "savedCount", sum(string({payload.results.status}) == "saved"));
    spec.ManifestName = "batch_crop_results.labkit.json";
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
