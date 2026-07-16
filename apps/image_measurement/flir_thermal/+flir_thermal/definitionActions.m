% App-owned V2 actions for FLIR Thermal. Handlers own portable source
% records, lightweight durable readings/ranges, one selected decode cache,
% and export boundaries without UI handles or control synchronization.
function actions = definitionActions()
    actions = struct( ...
        "filesChosen", @onFilesChosen, ...
        "removeFiles", @onRemoveFiles, ...
        "clearFiles", @onClearFiles, ...
        "selectionChanged", @onSelectionChanged, ...
        "previousImage", @onPreviousImage, ...
        "nextImage", @onNextImage, ...
        "autoRange", @onAutoRange, ...
        "groupRange", @onGroupRange, ...
        "perImageRange", @onPerImageRange, ...
        "roundRange", @onRoundRange, ...
        "paletteChanged", @onDisplaySettingChanged, ...
        "rangePresetChanged", @onRangePresetChanged, ...
        "rangeChanged", @onRangeChanged, ...
        "roiHotMode", @(state, event, services) setRoiMode( ...
            state, "hot", services), ...
        "roiColdMode", @(state, event, services) setRoiMode( ...
            state, "cold", services), ...
        "roiMeanMode", @(state, event, services) setRoiMode( ...
            state, "mean", services), ...
        "temperaturePointSelected", @onTemperaturePointSelected, ...
        "temperatureRegionSelected", @onTemperatureRegionSelected, ...
        "exportSettingChanged", @onExportSettingChanged, ...
        "chooseOutputFolder", @onChooseOutputFolder, ...
        "exportCurrent", @(state, event, services) exportSelection( ...
            state, true, services), ...
        "exportAll", @(state, event, services) exportSelection( ...
            state, false, services));
end

function state = onFilesChosen(state, event, services)
    requestedPaths = services.events.paths(event, "files");
    newSourcePaths = services.events.paths(event, "addedFiles");
    if isempty(newSourcePaths)
        newSourcePaths = requestedPaths;
    end
    if isempty(newSourcePaths)
        state = services.workflow.log(state, "FLIR file selection cancelled.");
        return;
    end
    try
        [addedItems, report] = flir_thermal.sourceFiles.readImages(newSourcePaths);
    catch ME
        state = reportFailure(state, "Could not read FLIR images", ME, services);
        return;
    end
    oldSources = state.project.inputs.sources;
    oldPaths = sourcePaths(oldSources);
    acceptedPaths = string({addedItems.path}).';
    desiredPaths = requestedPaths;
    if isempty(desiredPaths)
        desiredPaths = [oldPaths; acceptedPaths];
    end
    desiredPaths = desiredPaths(ismember(desiredPaths, ...
        [oldPaths; acceptedPaths]));
    sources = services.project.reconcileSources( ...
        oldSources, desiredPaths, "thermal-image", "thermal", true);
    annotations = reconcileAnnotations( ...
        state.project.annotations.items, sources, addedItems);
    state.project.inputs.sources = sources;
    state.project.annotations.items = annotations;
    state.session.selection.currentIndex = selectedIndex(sources, acceptedPaths);
    state.session.cache.currentItem = selectedLoadedItem( ...
        state, addedItems, services);
    state.project.parameters.outputFolder = string( ...
        services.dialogs.defaultOutputFolder(desiredPaths, "flir_thermal", ...
        state.project.parameters.outputFolder));
    state = invalidateResults(state);
    state = services.workflow.log(state, sprintf( ...
        'Registered %d FLIR source(s); decoded only newly added files.', ...
        numel(sources)));
    if report.skipped > 0
        services.dialogs.alert(importReportMessage(report), ...
            "Some FLIR files were skipped");
    end
end

function state = onRemoveFiles(state, event, services)
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
    state = reloadCurrent(state, services);
    state = invalidateResults(state);
end

function state = onClearFiles(state, ~, services)
    state.project.inputs.sources = labkit.ui.runtime.emptySourceRecords();
    state.project.annotations.items = repmat( ...
        flir_thermal.appState.emptyAnnotation(), 0, 1);
    state.session.selection.currentIndex = 0;
    state.session.cache.currentItem = [];
    state = invalidateResults(state);
    state = services.workflow.log(state, "Cleared loaded FLIR files.");
end

function state = onSelectionChanged(state, event, services)
    indices = services.events.indices(event, "selectedFiles", ...
        numel(state.project.inputs.sources));
    if isempty(indices)
        return;
    end
    state.session.selection.currentIndex = indices(1);
    state = reloadCurrent(state, services);
end

function state = onPreviousImage(state, ~, services)
    state.session.selection.currentIndex = max(1, ...
        state.session.selection.currentIndex - 1);
    state = reloadCurrent(state, services);
end

function state = onNextImage(state, ~, services)
    state.session.selection.currentIndex = min( ...
        numel(state.project.inputs.sources), ...
        state.session.selection.currentIndex + 1);
    state = reloadCurrent(state, services);
end

function state = onAutoRange(state, ~, services)
    item = state.session.cache.currentItem;
    if isempty(item)
        return;
    end
    item = setItemRange(item, autoRangeForItem(item), true);
    state = storeCurrentItem(state, item);
    state = invalidateResults(state);
    state = services.workflow.log(state, "Set the selected FLIR auto range.");
end

function state = onGroupRange(state, ~, services)
    [items, ok] = loadAllItems(state, services);
    if ~ok
        return;
    end
    ranges = zeros(numel(items), 2);
    for k = 1:numel(items)
        ranges(k, :) = autoRangeForItem(items(k));
    end
    sharedRange = normalizeRange([min(ranges(:, 1)), max(ranges(:, 2))]);
    for k = 1:numel(items)
        items(k).displayRange = sharedRange;
        items(k).rangeControlBounds = sharedRange;
        items(k).rangeAdjusted = true;
    end
    state = storeLoadedItems(state, items);
    state = invalidateResults(state);
    state = services.workflow.log(state, sprintf( ...
        'Set %d FLIR files to one shared range.', numel(items)));
end

function state = onPerImageRange(state, ~, services)
    [items, ok] = loadAllItems(state, services);
    if ~ok
        return;
    end
    for k = 1:numel(items)
        items(k) = setItemRange(items(k), autoRangeForItem(items(k)), true);
    end
    state = storeLoadedItems(state, items);
    state = invalidateResults(state);
    state = services.workflow.log(state, sprintf( ...
        'Set individual ranges for %d FLIR files.', numel(items)));
end

function state = onRoundRange(state, ~, services)
    annotations = state.project.annotations.items;
    count = 0;
    for k = 1:numel(annotations)
        if ~logical(annotations(k).rangeAdjusted)
            continue;
        end
        range = normalizeRange(annotations(k).displayRange);
        range = normalizeRange([floor(range(1)), ceil(range(2))]);
        annotations(k).displayRange = range;
        annotations(k).rangeControlBounds = controlBoundsContaining( ...
            range, annotations(k).rangeControlBounds);
        count = count + 1;
    end
    state.project.annotations.items = annotations;
    state = reloadCurrent(state, services);
    state = invalidateResults(state);
    state = services.workflow.log(state, sprintf( ...
        'Rounded %d already-set FLIR range(s).', count));
end

function state = onDisplaySettingChanged(state, event, ~)
    id = string(event.id);
    value = event.value;
    if id == "palette" && any(string(value) == ...
            ["turbo", "iron", "hot", "parula", "gray"])
        state.project.parameters.palette = string(value);
    elseif id == "colorMapping" && any(string(value) == ...
            ["Linear", "Log", "Gamma"])
        state.project.parameters.colorMapping = string(value);
    elseif id == "gammaValue"
        state.project.parameters.gammaValue = ...
            flir_thermal.userInterface.normalizeGammaValue(value);
    end
    state = invalidateResults(state);
end

function state = onRangePresetChanged(state, event, ~)
    item = state.session.cache.currentItem;
    if isempty(item)
        return;
    end
    preset = string(event.value);
    if ~any(preset == string(flir_thermal.userInterface.rangePresetItems()))
        return;
    end
    bounds = flir_thermal.userInterface.rangeControlBounds( ...
        item, preset, item.rangeControlBounds);
    item.rangePreset = preset;
    item.rangeControlBounds = bounds;
    range = clampRangeToBounds(item.displayRange, bounds);
    if ~isequaln(range, item.displayRange)
        item.displayRange = range;
        item.rangeAdjusted = true;
    end
    state = storeCurrentItem(state, item);
    state = invalidateResults(state);
end

function state = onRangeChanged(state, event, ~)
    item = state.session.cache.currentItem;
    if isempty(item)
        return;
    end
    range = normalizeRange(item.displayRange);
    if string(event.id) == "temperatureMin"
        range(1) = finiteScalar(event.value, range(1));
    elseif string(event.id) == "temperatureMax"
        range(2) = finiteScalar(event.value, range(2));
    end
    item.displayRange = normalizeRange(range);
    item.rangeAdjusted = true;
    state = storeCurrentItem(state, item);
    state = invalidateResults(state);
end

function state = setRoiMode(state, mode, services)
    state.project.parameters.roiMode = string(mode);
    state = services.workflow.log(state, "ROI mode: " + ...
        flir_thermal.userInterface.roiModeLabel(mode) + ...
        ". Drag on the thermal image to set the ROI.");
end

function state = onTemperaturePointSelected(state, event, services)
    item = state.session.cache.currentItem;
    if isempty(item)
        return;
    end
    [item, reading] = flir_thermal.appState.withManualPoint(item, event.value);
    if ~isfinite(reading.temperatureC)
        return;
    end
    state = storeCurrentItem(state, item);
    state = invalidateResults(state);
    state = services.workflow.log(state, sprintf( ...
        'Set manual point at x=%.0f, y=%.0f, %.2f C.', ...
        reading.x, reading.y, reading.temperatureC));
end

function state = onTemperatureRegionSelected(state, event, services)
    item = state.session.cache.currentItem;
    position = double(event.value(:).');
    if isempty(item) || numel(position) ~= 4 || ~all(isfinite(position))
        return;
    end
    startPoint = position(1:2);
    endPoint = startPoint + position(3:4);
    [item, reading] = flir_thermal.appState.withRoiReading( ...
        item, state.project.parameters.roiMode, startPoint, endPoint);
    if ~isfinite(reading.temperatureC)
        return;
    end
    state = storeCurrentItem(state, item);
    state = invalidateResults(state);
    state = services.workflow.log(state, "Set " + ...
        flir_thermal.userInterface.roiModeLabel( ...
        state.project.parameters.roiMode) + " ROI.");
end

function state = onExportSettingChanged(state, event, ~)
    format = upper(string(event.value));
    if any(format == ["PNG", "TIFF", "JPEG"])
        state.project.parameters.exportFormat = format;
        state = invalidateResults(state);
    end
end

function state = onChooseOutputFolder(state, ~, services)
    [folder, cancelled] = services.dialogs.outputFolder( ...
        "Select FLIR thermal export folder", ...
        state.project.parameters.outputFolder);
    if cancelled
        return;
    end
    state.project.parameters.outputFolder = string(folder);
    state = invalidateResults(state);
end

function state = exportSelection(state, currentOnly, services)
    sources = state.project.inputs.sources;
    if isempty(sources)
        services.dialogs.alert( ...
            "Load FLIR radiometric images before exporting.", ...
            "Export unavailable");
        return;
    end
    if currentOnly
        index = state.session.selection.currentIndex;
        sources = sources(index);
    end
    try
        items = loadSources(sources, state.project.annotations.items);
        p = state.project.parameters;
        opts = struct("outputFolder", p.outputFolder, ...
            "format", p.exportFormat, "palette", p.palette, ...
            "colorMapping", p.colorMapping, "gammaValue", p.gammaValue, ...
            "range", []);
        payload = flir_thermal.resultFiles.writeOutputs(items, opts);
        spec = struct();
        spec.Outputs = resultOutputs(payload.results, services);
        spec.Inputs = sources;
        spec.Parameters = p;
        spec.Summary = struct("imageCount", numel(items));
        spec.ManifestName = "flir_thermal.labkit.json";
        [manifestPath, ~] = services.results.writeManifest(p.outputFolder, spec);
    catch ME
        state = reportFailure(state, "Could not export FLIR images", ME, services);
        return;
    end
    payload.resultManifestPath = string(manifestPath);
    state.project.results.lastExport = payload;
    state.project.results.resultManifestPath = string(manifestPath);
    state = services.workflow.log(state, sprintf( ...
        'Exported %d FLIR image(s): %s', numel(items), payload.manifestPath));
end

function state = reloadCurrent(state, services)
    sources = state.project.inputs.sources;
    index = state.session.selection.currentIndex;
    if isempty(sources) || index < 1 || index > numel(sources)
        state.session.selection.currentIndex = 0;
        state.session.cache.currentItem = [];
        return;
    end
    try
        state.session.cache.currentItem = loadSources( ...
            sources(index), state.project.annotations.items);
    catch ME
        state.session.cache.currentItem = [];
        state = reportFailure(state, "Could not load FLIR image", ME, services);
    end
end

function state = storeCurrentItem(state, item)
    index = state.session.selection.currentIndex;
    sourceId = state.project.inputs.sources(index).id;
    annotations = state.project.annotations.items;
    annotationIndex = find(string({annotations.sourceId}) == string(sourceId), 1);
    annotation = flir_thermal.appState.annotationFromItem(item, sourceId);
    if isempty(annotationIndex)
        annotations(end + 1, 1) = annotation;
    else
        annotations(annotationIndex) = annotation;
    end
    state.project.annotations.items = annotations;
    state.session.cache.currentItem = item;
end

function state = storeLoadedItems(state, items)
    sources = state.project.inputs.sources;
    annotations = state.project.annotations.items;
    for k = 1:numel(items)
        index = find(sourcePaths(sources) == string(items(k).path), 1);
        if isempty(index)
            continue;
        end
        sourceId = sources(index).id;
        annotation = flir_thermal.appState.annotationFromItem(items(k), sourceId);
        annotationIndex = find(string({annotations.sourceId}) == string(sourceId), 1);
        annotations(annotationIndex) = annotation;
    end
    state.project.annotations.items = annotations;
    currentIndex = state.session.selection.currentIndex;
    if currentIndex >= 1 && currentIndex <= numel(sources)
        path = string(sources(currentIndex).reference.originalPath);
        itemIndex = find(string({items.path}) == path, 1);
        if ~isempty(itemIndex)
            state.session.cache.currentItem = items(itemIndex);
        end
    end
end

function [items, ok] = loadAllItems(state, services)
    ok = false;
    items = repmat(flir_thermal.appState.emptyItem(), 0, 1);
    try
        items = loadSources(state.project.inputs.sources, ...
            state.project.annotations.items);
        ok = numel(items) == numel(state.project.inputs.sources);
        if ~ok
            error('flir_thermal:UnreadableSource', ...
                'One or more registered FLIR sources could not be decoded.');
        end
    catch ME
        services.diagnostics.report("Could not load FLIR sources", ME);
        services.dialogs.alert(ME.message, "Could not load FLIR sources");
    end
end

function items = loadSources(sources, annotations)
    paths = sourcePaths(sources);
    items = flir_thermal.sourceFiles.readImages(paths);
    for k = 1:numel(items)
        sourceIndex = find(paths == string(items(k).path), 1);
        sourceId = sources(sourceIndex).id;
        annotationIndex = find(string({annotations.sourceId}) == string(sourceId), 1);
        if ~isempty(annotationIndex)
            items(k) = flir_thermal.appState.applyAnnotation( ...
                items(k), annotations(annotationIndex));
        end
    end
end

function item = selectedLoadedItem(state, addedItems, services)
    item = [];
    index = state.session.selection.currentIndex;
    if index < 1 || index > numel(state.project.inputs.sources)
        return;
    end
    path = string(state.project.inputs.sources(index).reference.originalPath);
    addedIndex = find(string({addedItems.path}) == path, 1);
    if ~isempty(addedIndex)
        annotation = annotationFor(state.project.annotations.items, ...
            state.project.inputs.sources(index).id);
        item = flir_thermal.appState.applyAnnotation(addedItems(addedIndex), annotation);
        return;
    end
    state = reloadCurrent(state, services);
    item = state.session.cache.currentItem;
end

function annotations = reconcileAnnotations(oldAnnotations, sources, addedItems)
    annotations = repmat(flir_thermal.appState.emptyAnnotation(), 0, 1);
    for k = 1:numel(sources)
        sourceId = string(sources(k).id);
        oldIndex = find(string({oldAnnotations.sourceId}) == sourceId, 1);
        if ~isempty(oldIndex)
            annotations(end + 1, 1) = oldAnnotations(oldIndex);
            continue;
        end
        path = string(sources(k).reference.originalPath);
        itemIndex = find(string({addedItems.path}) == path, 1);
        if ~isempty(itemIndex)
            annotations(end + 1, 1) = ...
                flir_thermal.appState.annotationFromItem( ...
                addedItems(itemIndex), sourceId);
        end
    end
end

function annotation = annotationFor(annotations, sourceId)
    annotation = [];
    index = find(string({annotations.sourceId}) == string(sourceId), 1);
    if ~isempty(index)
        annotation = annotations(index);
    end
end

function item = setItemRange(item, range, adjusted)
    item.displayRange = normalizeRange(range);
    item.rangeControlBounds = controlBoundsContaining( ...
        item.displayRange, item.rangeControlBounds);
    item.rangeAdjusted = logical(adjusted);
end

function range = autoRangeForItem(item)
    values = flir_thermal.userInterface.valueMatrix(item);
    values = values(isfinite(values));
    if isempty(values)
        range = normalizeRange(item.displayRange);
    else
        range = normalizeRange([min(values), max(values)]);
    end
end

function range = normalizeRange(value)
    range = double(value(:).');
    if numel(range) ~= 2 || ~all(isfinite(range))
        range = [20 40];
    end
    range = sort(range);
    if range(2) <= range(1)
        range(2) = range(1) + 1;
    end
end

function range = clampRangeToBounds(range, bounds)
    range = min(bounds(2), max(bounds(1), normalizeRange(range)));
    if range(2) <= range(1)
        range = normalizeRange(bounds);
    end
end

function bounds = controlBoundsContaining(range, bounds)
    range = normalizeRange(range);
    bounds = normalizeRange(bounds);
    bounds = [min(bounds(1), range(1)), max(bounds(2), range(2))];
end

function value = finiteScalar(candidate, fallback)
    value = double(candidate);
    if isempty(value) || ~isscalar(value) || ~isfinite(value)
        value = fallback;
    end
end

function paths = sourcePaths(sources)
    paths = strings(numel(sources), 1);
    for k = 1:numel(sources)
        paths(k) = string(sources(k).reference.originalPath);
    end
end

function index = selectedIndex(sources, newSourcePaths)
    index = double(~isempty(sources));
    for k = 1:numel(newSourcePaths)
        match = find(sourcePaths(sources) == newSourcePaths(k), 1);
        if ~isempty(match)
            index = match;
            return;
        end
    end
end

function message = importReportMessage(report)
    message = sprintf('Loaded %d compatible FLIR file(s) and skipped %d.', ...
        report.loaded, report.skipped);
    names = string({report.failures.name});
    if ~isempty(names)
        message = string(message) + newline + "Skipped: " + ...
            strjoin(names(1:min(5, numel(names))), ", ");
    end
end

function state = invalidateResults(state)
    state.project.results.lastExport = [];
    state.project.results.resultManifestPath = "";
end

function state = reportFailure(state, titleText, ME, services)
    services.diagnostics.report(titleText, ME);
    services.dialogs.alert(ME.message, titleText);
    state = services.workflow.log(state, titleText + ": " + string(ME.message));
end

function outputs = resultOutputs(results, services)
    outputs = services.results.emptyOutputs();
    fields = ["thermalImagePath", "colorbarPath", "temperatureCsvPath"];
    roles = ["thermal-image", "temperature-colorbar", "temperature-csv"];
    for k = 1:numel(results)
        for j = 1:numel(fields)
            path = string(results(k).(fields(j)));
            [~, name, extension] = fileparts(path);
            outputs(end + 1, 1) = services.results.output( ...
                roles(j) + "-" + string(k), roles(j), ...
                string(name) + string(extension), mediaType(extension), ...
                results(k).status, results(k).message);
        end
    end
end

function value = mediaType(extension)
    extension = lower(string(extension));
    if extension == ".csv"
        value = "text/csv";
    elseif any(extension == [".jpg", ".jpeg"])
        value = "image/jpeg";
    elseif any(extension == [".tif", ".tiff"])
        value = "image/tiff";
    else
        value = "image/png";
    end
end
