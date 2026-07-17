% App-owned V2 actions for Image Match. Handlers own source/reference records,
% durable match history, selected-image caches, and exports without UI access.
function actions = definitionActions()
    actions = struct( ...
        "referenceImageChosen", @onReferenceChosen, ...
        "sourceImagesChosen", @onSourcesChosen, ...
        "removeImages", @onRemoveImages, ...
        "clearImages", @onClearImages, ...
        "imageSelectionChanged", @onSelectionChanged, ...
        "previewModeChanged", @onPreviewModeChanged, ...
        "matchSettingChanged", @onMatchSettingChanged, ...
        "applyMatch", @onApplyMatch, ...
        "undoHistory", @onUndoHistory, ...
        "resetHistory", @onResetHistory, ...
        "exportSettingChanged", @onExportSettingChanged, ...
        "chooseOutputFolder", @onChooseOutputFolder, ...
        "exportImages", @onExportImages);
end

function state = onReferenceChosen(state, event, services)
    paths = services.events.paths(event, "addedFiles");
    if isempty(paths)
        state = services.workflow.log(state, "Reference selection cancelled.");
        return;
    end
    sources = state.project.inputs.sources;
    sources = sources(string({sources.role}) ~= "reference-image");
    reference = services.project.sourceRecord( ...
        "reference", "reference-image", paths(1), true);
    state.project.inputs.sources = [reference; sources(:)];
    state.session.cache.referenceItem = loadItem(paths(1), services);
    state.session.workflow.pendingDirty = false;
    state = invalidateResults(state);
    state = rebuildPreview(state);
    state = services.workflow.log(state, ...
        "Loaded reference image: " + displayName(paths(1)));
end

function state = onSourcesChosen(state, event, services)
    paths = services.events.paths(event, "files");
    added = services.events.paths(event, "addedFiles");
    if isempty(paths)
        paths = added;
    end
    if isempty(paths)
        state = services.workflow.log(state, "Image selection cancelled.");
        return;
    end
    allSources = state.project.inputs.sources;
    reference = allSources(string({allSources.role}) == "reference-image");
    oldSources = allSources(string({allSources.role}) == "source-image");
    sources = services.project.reconcileSources( ...
        oldSources, paths, "source-image", "image", true);
    state.project.inputs.sources = [reference(:); sources(:)];
    state.session.selection.currentIndex = selectedIndex(sources, added);
    state.session.cache.currentItem = loadItem( ...
        labkit.ui.runtime.sourcePaths( ...
        sources(state.session.selection.currentIndex)), services);
    state.project.parameters.outputFolder = string( ...
        services.dialogs.defaultOutputFolder(paths, "image_match", ...
        state.project.parameters.outputFolder));
    state.session.workflow.pendingDirty = false;
    state = invalidateResults(state);
    state = rebuildPreview(state);
    state = services.workflow.log(state, sprintf( ...
        'Registered %d source image(s); loaded the selected preview only.', ...
        numel(sources)));
end

function state = onRemoveImages(state, event, services)
    [reference, sources] = sourceGroups(state.project.inputs.sources);
    indices = services.events.indices(event, "removedFiles", numel(sources));
    if isempty(indices)
        return;
    end
    sources(indices) = [];
    state.project.inputs.sources = [reference(:); sources(:)];
    state.session.selection.currentIndex = min( ...
        state.session.selection.currentIndex, numel(sources));
    if isempty(sources)
        state.session.selection.currentIndex = 0;
        state.session.cache.currentItem = [];
    else
        path = labkit.ui.runtime.sourcePaths( ...
            sources(state.session.selection.currentIndex));
        state.session.cache.currentItem = loadItem(path, services);
    end
    state.session.workflow.pendingDirty = false;
    state = invalidateResults(state);
    state = rebuildPreview(state);
end

function state = onClearImages(state, ~, services)
    [reference, ~] = sourceGroups(state.project.inputs.sources);
    state.project.inputs.sources = reference;
    state.project.annotations.steps = repmat( ...
        image_match.analysisRun.emptyStep(), 0, 1);
    state.session.selection.currentIndex = 0;
    state.session.cache.currentItem = [];
    state.session.workflow.pendingDirty = false;
    state = invalidateResults(state);
    state = rebuildPreview(state);
    state = services.workflow.log(state, ...
        "Cleared source images and match history.");
end

function state = onSelectionChanged(state, event, services)
    [~, sources] = sourceGroups(state.project.inputs.sources);
    indices = services.events.indices(event, "selectedFiles", numel(sources));
    if isempty(indices)
        return;
    end
    state.session.selection.currentIndex = indices(1);
    state.session.cache.currentItem = loadItem( ...
        labkit.ui.runtime.sourcePaths(sources(indices(1))), services);
    state.session.workflow.pendingDirty = false;
    state = rebuildPreview(state);
end

function state = onPreviewModeChanged(state, event, ~)
    value = string(event.value);
    if isscalar(value) && any(value == ["Matched", "Original", "Before | After"])
        state.session.view.previewMode = value;
    end
end

function state = onMatchSettingChanged(state, event, ~)
    id = string(event.id);
    if id == "matchMethod"
        value = string(event.value);
        if any(value == string(image_match.userInterface.matchMethods()))
            state.project.parameters.matchMethod = value;
        end
    elseif any(id == ["matchStrength", "toneStrength", "colorStrength"])
        state.project.parameters.(char(id)) = boundedPercent(event.value, ...
            state.project.parameters.(char(id)));
    end
    state.session.workflow.pendingDirty = true;
    state = invalidateResults(state);
    state = rebuildPreview(state);
end

function state = onApplyMatch(state, ~, services)
    if ~ready(state)
        services.dialogs.alert( ...
            "Load source and reference images before applying a match.", ...
            "Match unavailable");
        return;
    end
    step = currentStep(state);
    state.project.annotations.steps(end + 1, 1) = step;
    state.session.workflow.pendingDirty = false;
    state = invalidateResults(state);
    state = rebuildPreview(state);
    state = services.workflow.log(state, "Applied match: " + string(step.label));
end

function state = onUndoHistory(state, ~, services)
    steps = state.project.annotations.steps;
    if isempty(steps)
        return;
    end
    removed = steps(end);
    steps(end) = [];
    state.project.annotations.steps = steps;
    state.session.workflow.pendingDirty = false;
    state = invalidateResults(state);
    state = rebuildPreview(state);
    state = services.workflow.log(state, "Undid match step: " + string(removed.label));
end

function state = onResetHistory(state, ~, services)
    state.project.annotations.steps = repmat( ...
        image_match.analysisRun.emptyStep(), 0, 1);
    state.session.workflow.pendingDirty = false;
    state = invalidateResults(state);
    state = rebuildPreview(state);
    state = services.workflow.log(state, "Reset match history.");
end

function state = onExportSettingChanged(state, event, ~)
    value = upper(string(event.value));
    if any(value == ["PNG", "TIFF", "JPEG"])
        state.project.parameters.exportFormat = value;
        state = invalidateResults(state);
    end
end

function state = onChooseOutputFolder(state, ~, services)
    [folder, cancelled] = services.dialogs.outputFolder( ...
        "Select image match export folder", ...
        state.project.parameters.outputFolder);
    if cancelled
        return;
    end
    state.project.parameters.outputFolder = string(folder);
    state = invalidateResults(state);
end

function state = onExportImages(state, ~, services)
    if ~ready(state)
        services.dialogs.alert( ...
            "Load source and reference images before exporting.", ...
            "Export unavailable");
        return;
    end
    [referenceSource, sources] = sourceGroups(state.project.inputs.sources);
    try
        items = loadItems(sources);
        reference = image_match.sourceFiles.readImages( ...
            labkit.ui.runtime.sourcePaths(referenceSource));
        reference = reference(1);
        opts = struct("outputFolder", state.project.parameters.outputFolder, ...
            "format", state.project.parameters.exportFormat);
        task = image_match.resultFiles.exportTask(items, reference, ...
            state.project.annotations.steps, opts);
        if ~isempty(state.project.results.lastExport) && ...
                state.project.results.lastExportFingerprint == task.fingerprint
            state = services.workflow.log(state, ...
                "Matched export is already up to date; skipped duplicate write.");
            return;
        end
        payload = image_match.resultFiles.writeOutputs(items, reference, ...
            state.project.annotations.steps, opts);
        spec = struct("Outputs", resultOutputs(payload.results, services), ...
            "Inputs", state.project.inputs.sources, ...
            "Parameters", state.project.parameters, ...
            "Summary", struct("imageCount", numel(items)), ...
            "ManifestName", "image_match.labkit.json");
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
    state = services.workflow.log(state, "Exported matched images: " + ...
        string(payload.manifestPath));
end

function state = rebuildPreview(state)
    cache = state.session.cache;
    cache.previewSource = [];
    cache.previewReference = [];
    cache.previewResult = [];
    cache.previewResultKey = "";
    if isempty(cache.currentItem) || isempty(cache.referenceItem)
        state.session.cache = cache;
        return;
    end
    cache.previewSource = image_match.userInterface.previewImage( ...
        cache.currentItem.image);
    cache.previewReference = image_match.userInterface.previewImage( ...
        cache.referenceItem.image);
    steps = state.project.annotations.steps;
    if state.session.workflow.pendingDirty
        steps(end + 1, 1) = currentStep(state);
    end
    processed = image_match.analysisRun.applyPipeline( ...
        {cache.previewSource}, steps, cache.previewReference);
    cache.previewResult = processed{1};
    cache.previewResultKey = strjoin(string({steps.label}), "|");
    state.session.cache = cache;
end

function step = currentStep(state)
    p = state.project.parameters;
    step = image_match.analysisRun.makeStep(p.matchMethod, ...
        p.matchStrength, p.toneStrength, p.colorStrength);
end

function item = loadItem(path, services)
    item = [];
    try
        loaded = image_match.sourceFiles.readImages(path);
        if ~isempty(loaded)
            item = loaded(1);
        end
    catch ME
        services.diagnostics.report("Could not load image", ME);
        services.dialogs.alert(ME.message, "Could not load image");
    end
end

function items = loadItems(sources)
    items = image_match.sourceFiles.readImages( ...
        labkit.ui.runtime.sourcePaths(sources));
end

function [reference, sources] = sourceGroups(allSources)
    roles = string({allSources.role});
    reference = allSources(roles == "reference-image");
    sources = allSources(roles == "source-image");
    if numel(reference) > 1
        reference = reference(1);
    end
end

function index = selectedIndex(sources, added)
    index = 1;
    if isempty(added)
        return;
    end
    match = find(labkit.ui.runtime.sourcePaths(sources) == ...
        string(added(1)), 1, 'first');
    if ~isempty(match)
        index = match;
    end
end

function tf = ready(state)
    tf = ~isempty(state.session.cache.currentItem) && ...
        ~isempty(state.session.cache.referenceItem);
end

function state = invalidateResults(state)
    state.project.results.lastExport = [];
    state.project.results.lastExportFingerprint = "";
    state.project.results.resultManifestPath = "";
end

function value = boundedPercent(value, fallback)
    value = double(value);
    if isempty(value) || ~isscalar(value) || ~isfinite(value)
        value = fallback;
    end
    value = min(max(value, 0), 100);
end

function name = displayName(path)
    [~, stem, extension] = fileparts(string(path));
    name = string(stem) + string(extension);
end

function outputs = resultOutputs(results, services)
    outputs = services.results.emptyOutputs();
    for k = 1:numel(results)
        [~, name, extension] = fileparts(results(k).outputPath);
        outputs(end + 1, 1) = services.results.output("matched-" + string(k), ...
            "matched-image", string(name) + string(extension), ...
            mediaType(extension), results(k).status, results(k).message);
    end
end

function value = mediaType(extension)
    if any(lower(string(extension)) == [".jpg", ".jpeg"])
        value = "image/jpeg";
    elseif any(lower(string(extension)) == [".tif", ".tiff"])
        value = "image/tiff";
    else
        value = "image/png";
    end
end
