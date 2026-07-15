% App-owned V2 action registry for Image Enhance. Handlers receive canonical
% state/events/services and own sources, histories, ROI annotations, previews,
% and exports without reading UI controls or retaining graphics handles.
function actions = definitionActions()
    actions = struct( ...
        "sourceImagesChosen", @onSourceImagesChosen, ...
        "removeImages", @onRemoveImages, ...
        "clearImages", @onClearImages, ...
        "imageSelectionChanged", @onImageSelectionChanged, ...
        "batchModeChanged", @onBatchModeChanged, ...
        "previewModeChanged", @onPreviewModeChanged, ...
        "toolChanged", @onToolChanged, ...
        "toolSettingChanged", @onToolSettingChanged, ...
        "setWhiteRoi", @onSetWhiteRoi, ...
        "whiteRoiEdited", @onWhiteRoiEdited, ...
        "applyTool", @onApplyTool, ...
        "undoHistory", @onUndoHistory, ...
        "resetHistory", @onResetHistory, ...
        "exportSettingChanged", @onExportSettingChanged, ...
        "chooseOutputFolder", @onChooseOutputFolder, ...
        "exportImages", @onExportImages);
end

function state = onSourceImagesChosen(state, event, services)
    paths = services.events.paths(event, "files");
    added = services.events.paths(event, "addedFiles");
    if isempty(paths)
        paths = added;
    end
    if isempty(paths)
        state = services.workflow.log(state, "Image selection cancelled.");
        return;
    end
    [sources, annotations] = reconcileSources(state, paths, services);
    state.project.inputs.sources = sources;
    state.project.annotations.items = annotations;
    state.session.selection.currentIndex = selectedIndex(sources, added);
    state.project.parameters.outputFolder = string( ...
        services.dialogs.defaultOutputFolder(paths, "image_enhance", ...
        state.project.parameters.outputFolder));
    state.session.workflow.pendingDirty = false;
    state.session.view.roiEditing = false;
    state = invalidateResultsAndPreview(state);
    state = image_enhance.ensureCurrentPreview(state, services);
    state = rebuildPreview(state);
    state = services.workflow.log(state, sprintf( ...
        'Registered %d image source(s); loaded the selected preview only.', ...
        numel(sources)));
end

function state = onRemoveImages(state, event, services)
    sources = state.project.inputs.sources;
    indices = services.events.indices(event, "removedFiles", numel(sources));
    if isempty(indices)
        return;
    end
    removedIds = string({sources(indices).id});
    sources(indices) = [];
    annotations = state.project.annotations.items;
    annotations(ismember(string({annotations.sourceId}), removedIds)) = [];
    state.project.inputs.sources = sources;
    state.project.annotations.items = annotations;
    state.session.selection.currentIndex = min( ...
        state.session.selection.currentIndex, numel(sources));
    if isempty(sources)
        state.session.selection.currentIndex = 0;
    end
    state.session.workflow.pendingDirty = false;
    state.session.view.roiEditing = false;
    state = invalidateResultsAndPreview(state);
    state = image_enhance.ensureCurrentPreview(state, services);
    state = rebuildPreview(state);
    state = services.workflow.log(state, sprintf( ...
        'Removed image source(s); %d remaining.', numel(sources)));
end

function state = onClearImages(state, ~, services)
    state.project.inputs.sources = emptySources();
    state.project.annotations.items = repmat( ...
        image_enhance.appState.emptyAnnotation(), 0, 1);
    state.project.annotations.sharedSteps = repmat( ...
        image_enhance.appState.emptyStep(), 0, 1);
    state.session.selection.currentIndex = 0;
    state.session.workflow.pendingDirty = false;
    state.session.view.roiEditing = false;
    state = invalidateResultsAndPreview(state);
    state = services.workflow.log(state, ...
        "Cleared image sources and enhancement history.");
end

function state = onImageSelectionChanged(state, event, services)
    indices = services.events.indices(event, "selectedFiles", ...
        numel(state.project.inputs.sources));
    if isempty(indices)
        return;
    end
    state.session.selection.currentIndex = indices(1);
    state.session.workflow.pendingDirty = false;
    state.session.view.roiEditing = false;
    state = invalidatePreview(state);
    state = image_enhance.ensureCurrentPreview(state, services);
    state = rebuildPreview(state);
end

function state = onBatchModeChanged(state, event, ~)
    state.project.parameters.batchMode = logical(event.value);
    state.session.workflow.pendingDirty = false;
    state.session.view.roiEditing = false;
    state = invalidateResultsAndProcessedPreview(state);
    state = rebuildPreview(state);
end

function state = onPreviewModeChanged(state, event, ~)
    value = string(event.value);
    if isscalar(value) && any(value == ["Enhanced", "Original", "Before | After"])
        state.session.view.previewMode = value;
    end
end

function state = onToolChanged(state, event, ~)
    value = string(event.value);
    if ~isscalar(value) || ~any(value == string(image_enhance.userInterface.toolKinds()))
        return;
    end
    defaults = image_enhance.analysisRun.defaultStepValues(value);
    state.session.view.toolKind = value;
    state.session.view.toolAmount = defaults.amount;
    state.session.view.toolSecondary = defaults.secondary;
    state.session.view.roiEditing = false;
    state.session.workflow.pendingDirty = true;
    state = invalidateResultsAndProcessedPreview(state);
    state = rebuildPreview(state);
end

function state = onToolSettingChanged(state, event, ~)
    defaults = image_enhance.analysisRun.defaultStepValues( ...
        state.session.view.toolKind);
    value = finiteScalar(event.value, 0);
    if string(event.id) == "toolSecondary"
        state.session.view.toolSecondary = image_enhance.appState.clampValue( ...
            value, defaults.secondaryLimits);
    else
        state.session.view.toolAmount = image_enhance.appState.clampValue( ...
            value, defaults.amountLimits);
    end
    state.session.workflow.pendingDirty = true;
    state = invalidateResultsAndProcessedPreview(state);
    state = rebuildPreview(state);
end

function state = onSetWhiteRoi(state, ~, services)
    if ~hasCurrentSource(state) || state.project.parameters.batchMode
        services.dialogs.alert( ...
            "White ROI calibration uses per-image mode only.", ...
            "White ROI unavailable");
        return;
    end
    index = currentIndex(state);
    annotation = state.project.annotations.items(index);
    if ~hasWhiteRoi(annotation)
        annotation.whiteRoi = image_enhance.userInterface.defaultWhiteRoi( ...
            size(state.session.cache.item.image));
        state.project.annotations.items(index) = annotation;
    end
    state.session.view.roiEditing = true;
    state.session.view.previewMode = "Original";
    state.session.workflow.pendingDirty = true;
    state = invalidateResultsAndProcessedPreview(state);
end

function state = onWhiteRoiEdited(state, event, ~)
    if ~hasCurrentSource(state)
        return;
    end
    position = double(event.value);
    if numel(position) ~= 4 || any(~isfinite(position)) || ...
            any(position(3:4) <= 0)
        return;
    end
    scale = max(eps, state.session.cache.previewScale);
    state.project.annotations.items(currentIndex(state)).whiteRoi = ...
        position ./ scale;
    state.session.workflow.pendingDirty = true;
    state = invalidateResultsAndProcessedPreview(state);
end

function state = onApplyTool(state, ~, services)
    availability = image_enhance.userInterface.toolAvailability( ...
        state, state.session.view.toolKind);
    if ~availability.canApply
        services.dialogs.alert(availability.status, "Tool unavailable");
        return;
    end
    step = currentToolStep(state);
    steps = image_enhance.appState.activeSteps(state);
    steps(end + 1, 1) = step;
    state = image_enhance.appState.setActiveSteps(state, steps);
    state.session.workflow.pendingDirty = false;
    state.session.view.roiEditing = false;
    state = invalidateResultsAndProcessedPreview(state);
    state = rebuildPreview(state);
    state = services.workflow.log(state, "Applied tool: " + string(step.label));
end

function state = onUndoHistory(state, ~, services)
    steps = image_enhance.appState.activeSteps(state);
    if isempty(steps)
        return;
    end
    removed = steps(end);
    steps(end) = [];
    state = image_enhance.appState.setActiveSteps(state, steps);
    state.session.workflow.pendingDirty = false;
    state = invalidateResultsAndProcessedPreview(state);
    state = rebuildPreview(state);
    state = services.workflow.log(state, "Undid history step: " + string(removed.label));
end

function state = onResetHistory(state, ~, services)
    if isempty(image_enhance.appState.activeSteps(state))
        return;
    end
    state = image_enhance.appState.setActiveSteps(state, repmat( ...
        image_enhance.appState.emptyStep(), 0, 1));
    state.session.workflow.pendingDirty = false;
    state = invalidateResultsAndProcessedPreview(state);
    state = rebuildPreview(state);
    state = services.workflow.log(state, "Reset enhancement history.");
end

function state = onExportSettingChanged(state, event, ~)
    value = upper(string(event.value));
    if isscalar(value) && any(value == ["PNG", "TIFF", "JPEG"])
        state.project.parameters.exportFormat = value;
        state = invalidateResults(state);
    end
end

function state = onChooseOutputFolder(state, ~, services)
    [folder, cancelled] = services.dialogs.outputFolder( ...
        "Select image enhancement export folder", ...
        state.project.parameters.outputFolder);
    if cancelled
        state = services.workflow.log(state, "Export folder selection cancelled.");
        return;
    end
    state.project.parameters.outputFolder = string(folder);
    state = invalidateResults(state);
end

function state = onExportImages(state, ~, services)
    if isempty(state.project.inputs.sources)
        services.dialogs.alert("Load images before exporting.", "No images loaded");
        return;
    end
    try
        items = loadExportItems(state);
        [steps, itemSteps] = exportSteps(state);
        opts = struct("outputFolder", state.project.parameters.outputFolder, ...
            "format", state.project.parameters.exportFormat, ...
            "itemSteps", {itemSteps});
        task = image_enhance.appState.exportTask(items, steps, opts);
        if ~isempty(state.project.results.lastExport) && ...
                state.project.results.lastExportFingerprint == task.fingerprint
            state = services.workflow.log(state, ...
                "Enhanced export is already up to date; skipped duplicate write.");
            return;
        end
        payload = image_enhance.resultFiles.writeOutputs(items, steps, opts);
        outputs = resultOutputs(payload.results, services);
        spec = struct("Outputs", outputs, ...
            "Inputs", state.project.inputs.sources, ...
            "Parameters", state.project.parameters, ...
            "Summary", struct("imageCount", numel(items), ...
                "savedCount", sum(string({payload.results.status}) == "saved")), ...
            "ManifestName", "image_enhance.labkit.json");
        [manifestPath, ~] = services.results.writeManifest( ...
            state.project.parameters.outputFolder, spec);
    catch ME
        services.diagnostics.report("Export failed", ME);
        services.dialogs.alert(ME.message, "Export failed");
        return;
    end
    payload.resultManifestPath = string(manifestPath);
    state.project.results.lastExport = payload;
    state.project.results.lastExportFingerprint = task.fingerprint;
    state.project.results.resultManifestPath = string(manifestPath);
    statuses = string({payload.results.status});
    state = services.workflow.log(state, sprintf( ...
        'Exported %d image(s), %d failed. Manifest: %s', ...
        sum(statuses == "saved"), sum(statuses == "failed"), ...
        char(payload.manifestPath)));
end

function [sources, annotations] = reconcileSources(state, paths, services)
    paths = labkit.image.normalizePaths(paths);
    oldSources = state.project.inputs.sources;
    oldAnnotations = state.project.annotations.items;
    sources = emptySources();
    annotations = repmat(image_enhance.appState.emptyAnnotation(), numel(paths), 1);
    for k = 1:numel(paths)
        oldIndex = sourceIndexForPath(oldSources, paths(k));
        if isempty(oldIndex)
            id = nextSourceId(oldSources, sources);
            source = services.project.sourceRecord(id, "source-image", paths(k), true);
            annotation = image_enhance.appState.emptyAnnotation();
            annotation.sourceId = id;
        else
            source = oldSources(oldIndex);
            annotationIndex = find(string({oldAnnotations.sourceId}) == ...
                string(source.id), 1);
            annotation = image_enhance.appState.emptyAnnotation();
            annotation.sourceId = string(source.id);
            if ~isempty(annotationIndex)
                annotation = oldAnnotations(annotationIndex);
            end
        end
        sources(end + 1, 1) = source;
        annotations(k) = annotation;
    end
end

function index = sourceIndexForPath(sources, path)
    index = [];
    if ~isempty(sources)
        index = find(string(arrayfun(@(s) s.reference.originalPath, ...
            sources, 'UniformOutput', false)) == string(path), 1);
    end
end

function id = nextSourceId(oldSources, newSources)
    count = numel(oldSources) + numel(newSources) + 1;
    ids = [string({oldSources.id}), string({newSources.id})];
    id = "image-" + string(count);
    while any(ids == id)
        count = count + 1;
        id = "image-" + string(count);
    end
end

function index = selectedIndex(sources, added)
    index = 1;
    if isempty(added)
        return;
    end
    match = sourceIndexForPath(sources, added(1));
    if ~isempty(match)
        index = match;
    end
end

function state = rebuildPreview(state)
    if isempty(state.session.cache.previewSource)
        state.session.cache.previewResult = [];
        state.session.cache.previewResultKey = "";
        return;
    end
    steps = image_enhance.appState.activeSteps(state);
    availability = image_enhance.userInterface.toolAvailability( ...
        state, state.session.view.toolKind);
    includePending = state.session.workflow.pendingDirty && ...
        availability.canPreviewPending;
    previewSteps = steps;
    if includePending
        previewSteps(end + 1, 1) = currentToolStep(state);
    end
    key = strjoin(string({previewSteps.label}), "|") + ...
        "#" + string(numel(previewSteps)) + ...
        "#" + string(includePending);
    if state.session.cache.previewResultKey == key && ...
            ~isempty(state.session.cache.previewResult)
        return;
    end
    roi = state.project.annotations.items(currentIndex(state)).whiteRoi;
    state.session.cache.previewResult = image_enhance.appState.previewResult( ...
        state.session.cache.previewSource, previewSteps, roi, ...
        state.session.cache.previewScale);
    state.session.cache.previewResultKey = key;
end

function step = currentToolStep(state)
    step = image_enhance.analysisRun.makeStep( ...
        state.session.view.toolKind, state.session.view.toolAmount, ...
        state.session.view.toolSecondary, 0);
end

function items = loadExportItems(state)
    sources = state.project.inputs.sources;
    paths = strings(numel(sources), 1);
    for k = 1:numel(sources)
        paths(k) = string(sources(k).reference.originalPath);
    end
    items = image_enhance.sourceFiles.readImages(paths);
    for k = 1:numel(items)
        items(k).whiteRoi = state.project.annotations.items(k).whiteRoi;
    end
end

function [steps, itemSteps] = exportSteps(state)
    if state.project.parameters.batchMode
        steps = state.project.annotations.sharedSteps;
        itemSteps = {};
    else
        steps = repmat(image_enhance.appState.emptyStep(), 0, 1);
        itemSteps = {state.project.annotations.items.steps}.';
    end
end

function outputs = resultOutputs(results, services)
    outputs = repmat(services.results.output("", "", "", ""), ...
        numel(results), 1);
    for k = 1:numel(results)
        [~, name, extension] = fileparts(results(k).outputPath);
        outputs(k) = services.results.output("enhanced-" + string(k), ...
            "enhanced-image", string(name) + string(extension), ...
            mediaType(extension), results(k).status, results(k).message);
    end
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

function state = invalidateResultsAndPreview(state)
    state = invalidateResults(state);
    state = invalidatePreview(state);
end

function state = invalidateResultsAndProcessedPreview(state)
    state = invalidateResults(state);
    state.session.cache.previewResult = [];
    state.session.cache.previewResultKey = "";
end

function state = invalidateResults(state)
    state.project.results.lastExport = [];
    state.project.results.lastExportFingerprint = "";
    state.project.results.resultManifestPath = "";
end

function state = invalidatePreview(state)
    state.session.cache.sourceId = "";
    state.session.cache.item = [];
    state.session.cache.previewSource = [];
    state.session.cache.previewScale = 1;
    state.session.cache.previewResult = [];
    state.session.cache.previewResultKey = "";
end

function tf = hasCurrentSource(state)
    index = currentIndex(state);
    tf = index >= 1 && index <= numel(state.project.inputs.sources) && ...
        index <= numel(state.project.annotations.items) && ...
        ~isempty(state.session.cache.item);
end

function index = currentIndex(state)
    index = state.session.selection.currentIndex;
end

function tf = hasWhiteRoi(annotation)
    roi = double(annotation.whiteRoi);
    tf = numel(roi) == 4 && all(isfinite(roi)) && all(roi(3:4) > 0);
end

function value = finiteScalar(value, fallback)
    value = double(value);
    if isempty(value) || ~isscalar(value) || ~isfinite(value)
        value = fallback;
    end
end

function sources = emptySources()
    sources = struct("id", {}, "required", {}, "role", {}, "reference", {});
end
