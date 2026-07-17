% App-owned V2 action registry for Batch Image Crop. Handlers receive
% canonical state/events/services and own source queues, crop annotations,
% scale calibration, and exports without reading or mutating UI controls.
function actions = definitionActions()
    actions = struct( ...
        "imagesChosen", @onImagesChosen, ...
        "removeImages", @onRemoveImages, ...
        "clearImages", @onClearImages, ...
        "duplicateImage", @onDuplicateImage, ...
        "imageSelectionChanged", @onImageSelectionChanged, ...
        "previousImage", @onPreviousImage, ...
        "nextImage", @onNextImage, ...
        "cropGeometryChanged", @onCropGeometryChanged, ...
        "rotationChanged", @onRotationChanged, ...
        "paddingChanged", @onPaddingChanged, ...
        "centerChanged", @onCenterChanged, ...
        "useImageCenter", @onUseImageCenterXY, ...
        "useImageXCenter", @onUseImageCenterX, ...
        "useImageYCenter", @onUseImageCenterY, ...
        "scaleSettingChanged", @onScaleSettingChanged, ...
        "scaleCalibrationFieldChanged", @onScaleCalibrationFieldChanged, ...
        "measureScaleReference", @onMeasureScaleReference, ...
        "scaleReferenceEdited", @onScaleReferenceEdited, ...
        "scaleBarSettingChanged", @onScaleBarSettingChanged, ...
        "placeScaleBar", @onPlaceScaleBar, ...
        "cropCenterEdited", @onCropCenterEdited);
    actions = mergeActions(actions, ...
        batch_crop.resultFiles.definitionActions());
end

function state = onImagesChosen(state, event, services)
    added = services.events.paths(event, "addedFiles");
    paths = services.events.paths(event, "files");
    if isempty(paths)
        paths = added;
    end
    if isempty(paths)
        state = services.workflow.log(state, "Image file selection cancelled.");
        return;
    end
    [tasks, sources, images] = batch_crop.sourceFiles.reconcileSelection( ...
        state.project.inputs.items, state.project.inputs.sources, ...
        state.session.cache.images, paths, services.project.sourceRecord);
    state.project.inputs.items = tasks;
    state.project.inputs.sources = sources;
    state.session.cache.images = images;
    state.session.selection.currentIndex = selectedAddedIndex( ...
        tasks, sources, added);
    state.project.parameters.outputFolder = string( ...
        services.dialogs.defaultOutputFolder(paths, "batch_crop", ...
        state.project.parameters.outputFolder));
    state = clearExportAndCanvas(state);
    [state, loaded] = ensureCurrentImageLoaded(state, services);
    if loaded
        state = ensureCurrentCenter(state);
        state = initializeCropSizeDefaultsIfNeeded(state);
    end
    state = services.workflow.log(state, sprintf( ...
        'Selected %d image file(s); crop tasks: %d.', ...
        numel(paths), numel(state.project.inputs.items)));
end

function state = onClearImages(state, ~, services)
    state.project.inputs.items = repmat( ...
        batch_crop.cropTasks.emptyTask(), 0, 1);
    state.project.inputs.sources = labkit.ui.runtime.emptySourceRecords();
    state.session.cache.images = cell(0, 1);
    state.session.selection.currentIndex = 0;
    state.session.workflow.cropDefaultsInitialized = false;
    state.session.workflow.scaleReferenceEditing = false;
    state.session.view.scaleBar = [];
    state = clearExportAndCanvas(state);
    state = services.workflow.log(state, "Cleared loaded images.");
end

function state = onRemoveImages(state, event, services)
    items = state.project.inputs.items;
    indices = services.events.indices(event, "removedFiles", numel(items));
    if isempty(indices)
        return;
    end
    items(indices) = [];
    state.project.inputs.items = items;
    state.session.cache.images(indices) = [];
    state.project.inputs.sources = sourcesForTasks( ...
        items, state.project.inputs.sources);
    if isempty(items)
        state.session.selection.currentIndex = 0;
    else
        state.session.selection.currentIndex = min(max( ...
            state.session.selection.currentIndex, 1), numel(items));
    end
    state.session.workflow.scaleReferenceEditing = false;
    state.session.view.scaleBar = [];
    state = clearExportAndCanvas(state);
    [state, loaded] = ensureCurrentImageLoaded(state, services);
    if loaded
        state = ensureCurrentCenter(state);
    end
    state = services.workflow.log(state, sprintf( ...
        'Removed %d crop task(s); remaining: %d.', ...
        numel(indices), numel(items)));
end

function state = onDuplicateImage(state, ~, services)
    [state, ok] = ensureCurrentReady(state, services);
    if ~ok
        return;
    end
    index = currentIndex(state);
    duplicate = state.project.inputs.items(index);
    duplicate.centerXY = [NaN, NaN];
    duplicate.centerSet = false;
    insertAt = index + 1;
    items = state.project.inputs.items;
    state.project.inputs.items = [items(1:index); duplicate; items(insertAt:end)];
    images = state.session.cache.images;
    state.session.cache.images = [images(1:index); images(index); images(insertAt:end)];
    state.session.selection.currentIndex = insertAt;
    state.session.workflow.scaleReferenceEditing = false;
    state.session.view.scaleBar = [];
    state = clearExportAndCanvas(state);
    state = ensureCurrentCenter(state);
    state = services.workflow.log(state, sprintf( ...
        'Duplicated image %d as crop task %d. Pick a new crop center.', ...
        index, insertAt));
end

function state = onImageSelectionChanged(state, event, services)
    indices = services.events.indices(event, "selectedFiles", ...
        numel(state.project.inputs.items));
    if isempty(indices)
        return;
    end
    state.session.selection.currentIndex = indices(1);
    state.session.workflow.scaleReferenceEditing = false;
    state.session.view.scaleBar = [];
    [state, loaded] = ensureCurrentImageLoaded(state, services);
    if loaded
        state = ensureCurrentCenter(state);
    end
end

function state = onPreviousImage(state, ~, services)
    if isempty(state.project.inputs.items)
        return;
    end
    state.session.selection.currentIndex = max(1, currentIndex(state) - 1);
    state = selectCurrentImage(state, services);
end

function state = onNextImage(state, ~, services)
    if isempty(state.project.inputs.items)
        return;
    end
    state.session.selection.currentIndex = min( ...
        numel(state.project.inputs.items), currentIndex(state) + 1);
    state = selectCurrentImage(state, services);
end

function state = selectCurrentImage(state, services)
    state.session.workflow.scaleReferenceEditing = false;
    state.session.view.scaleBar = [];
    [state, loaded] = ensureCurrentImageLoaded(state, services);
    if loaded
        state = ensureCurrentCenter(state);
    end
end

function state = onCropGeometryChanged(state, ~, services)
    parameters = state.project.parameters;
    parameters.cropWidth = positiveInteger(parameters.cropWidth, 1);
    parameters.cropHeight = positiveInteger(parameters.cropHeight, 1);
    state.project.parameters = parameters;
    state.session.workflow.cropDefaultsInitialized = true;
    [state, ok] = ensureCurrentReady(state, services);
    if ok
        state = ensureCurrentCenter(state);
    end
    state = clearExport(state);
end

function state = onRotationChanged(state, event, services)
    [state, ok] = ensureCurrentReady(state, services);
    if ~ok
        return;
    end
    index = currentIndex(state);
    state.project.inputs.items(index).angleDeg = finiteScalar(event.value, ...
        state.project.inputs.items(index).angleDeg);
    state = ensureCurrentCenter(state);
    state = clearExportAndCanvas(state);
    state.session.view.scaleBar = [];
    state = services.workflow.log(state, sprintf( ...
        'Updated rotation for image %d: %.3g deg.', index, ...
        state.project.inputs.items(index).angleDeg));
end

function state = onPaddingChanged(state, event, services)
    [state, ok] = ensureCurrentReady(state, services);
    if ~ok
        return;
    end
    index = currentIndex(state);
    value = finiteScalar(event.value, ...
        state.project.inputs.items(index).paddingPercent);
    state.project.inputs.items(index).paddingPercent = min(max(value, 0), 200);
    state = ensureCurrentCenter(state);
    state = clearExportAndCanvas(state);
    state.session.view.scaleBar = [];
    state = services.workflow.log(state, sprintf( ...
        'Updated padding for image %d: %.3g%%.', index, ...
        state.project.inputs.items(index).paddingPercent));
end

function state = onCenterChanged(state, event, services)
    [state, ok] = ensureCurrentReady(state, services);
    if ~ok
        return;
    end
    index = currentIndex(state);
    center = state.project.inputs.items(index).centerXY;
    if event.target == "centerX"
        center(1) = finiteScalar(event.value, center(1));
    elseif event.target == "centerY"
        center(2) = finiteScalar(event.value, center(2));
    end
    state = setCurrentCenter(state, center, true);
    state = clearExport(state);
    state = services.workflow.log(state, sprintf( ...
        'Set crop center for image %d: x=%.1f, y=%.1f.', index, ...
        state.project.inputs.items(index).centerXY));
end

function state = onUseImageCenterXY(state, event, services)
    state = onUseImageCenter(state, event, services, "xy");
end

function state = onUseImageCenterX(state, event, services)
    state = onUseImageCenter(state, event, services, "x");
end

function state = onUseImageCenterY(state, event, services)
    state = onUseImageCenter(state, event, services, "y");
end

function state = onUseImageCenter(state, ~, services, mode)
    [state, ok] = ensureCurrentReady(state, services);
    if ~ok
        return;
    end
    index = currentIndex(state);
    item = currentItem(state);
    center = item.centerXY;
    sourceCenter = batch_crop.cropGeometry.sourceCenterXY(item.image);
    if any(~isfinite(center))
        center = sourceCenter;
    end
    if mode == "x"
        center(1) = sourceCenter(1);
    elseif mode == "y"
        center(2) = sourceCenter(2);
    else
        center = sourceCenter;
    end
    state = setCurrentCenter(state, center, true);
    state = clearExport(state);
    state = services.workflow.log(state, sprintf( ...
        'Set image %d crop %s center.', index, char(upper(mode))));
end

function state = onScaleSettingChanged(state, ~, ~)
    parameters = state.project.parameters;
    parameters.physicalWidth = positiveScalar(parameters.physicalWidth, eps);
    parameters.physicalHeight = positiveScalar(parameters.physicalHeight, eps);
    parameters.targetPixelsPerUnit = nonnegativeScalar( ...
        parameters.targetPixelsPerUnit, 0);
    parameters.maxUpsamplePercent = nonnegativeScalar( ...
        parameters.maxUpsamplePercent, 0);
    state.project.parameters = parameters;
    if ~strcmpi(parameters.scaleMode, "Physical")
        state.session.workflow.scaleReferenceEditing = false;
    end
    state = clearExport(state);
end

function state = onScaleCalibrationFieldChanged(state, event, ~)
    if ~hasCurrentImage(state)
        return;
    end
    index = currentIndex(state);
    cal = state.project.inputs.items(index).scaleCalibration;
    if event.target == "scaleReferencePixels"
        cal.referencePixels = positiveOrNaN(event.value);
        cal.referenceLine = zeros(0, 2);
    elseif event.target == "scaleReferenceLength"
        cal.referenceLength = nonnegativeScalar(event.value, cal.referenceLength);
    elseif event.target == "scaleCalibrationUnit"
        cal.unit = char(string(event.value));
    end
    state.project.inputs.items(index).scaleCalibration = calibrationFrom(cal);
    state.session.view.scaleBar = [];
    state = clearExport(state);
end

function state = onMeasureScaleReference(state, ~, services)
    if ~hasCurrentImage(state)
        showError(services, 'No image loaded', ...
            'Open an image before measuring reference pixels.');
        return;
    end
    state.session.workflow.scaleReferenceEditing = ...
        ~state.session.workflow.scaleReferenceEditing;
    state.session.view.scaleBar = [];
end

function state = onScaleReferenceEdited(state, event, ~)
    if ~hasCurrentImage(state)
        return;
    end
    points = double(event.value);
    if size(points, 2) ~= 2
        return;
    end
    [geometry, placement] = currentGeometryAndPlacement(state);
    original = zeros(size(points));
    for k = 1:size(points, 1)
        original(k, :) = batch_crop.cropGeometry.canvasToOriginal( ...
            geometry, points(k, :) - placement.offset);
    end
    index = currentIndex(state);
    cal = state.project.inputs.items(index).scaleCalibration;
    cal.referenceLine = original;
    cal.referencePixels = NaN;
    state.project.inputs.items(index).scaleCalibration = calibrationFrom(cal);
    state.session.view.scaleBar = [];
    state = clearExport(state);
end

function state = onScaleBarSettingChanged(state, ~, ~)
    state.project.parameters.scaleBarLength = nonnegativeScalar( ...
        state.project.parameters.scaleBarLength, 0);
    state.session.view.scaleBar = [];
end

function state = onPlaceScaleBar(state, ~, services)
    if ~hasCurrentImage(state)
        showError(services, 'No image loaded', ...
            'Open an image before placing a scale bar.');
        return;
    end
    item = currentItem(state);
    if ~batch_crop.scaleCalibration.isSet(item.scaleCalibration)
        showError(services, 'Calibration required', ...
            ['Measure or enter reference pixels, then enter a positive ' ...
            'reference length and unit.']);
        return;
    end
    try
        state.session.view.scaleBar = labkit.ui.interaction.scaleBarGeometry( ...
            size(item.image), item.scaleCalibration, ...
            state.project.parameters.scaleBarLength, ...
            state.project.parameters.scaleBarPosition, ...
            state.project.parameters.scaleBarColor);
        state.session.workflow.scaleReferenceEditing = false;
    catch ME
        showError(services, 'Could not place scale bar', ME.message);
    end
end

function state = onCropCenterEdited(state, event, services)
    [state, ok] = ensureCurrentReady(state, services);
    if ~ok || ~isstruct(event.value) || ...
            ~isfield(event.value, 'points') || ...
            size(event.value.points, 2) ~= 2 || isempty(event.value.points)
        return;
    end
    [geometry, placement] = currentGeometryAndPlacement(state);
    canvas = double(event.value.points(1, :)) - placement.offset;
    center = batch_crop.cropGeometry.canvasToOriginal(geometry, canvas);
    state = setCurrentCenter(state, center, true);
    state = clearExport(state);
    action = "Placed";
    if isfield(event.value, 'reason') && string(event.value.reason) == "move"
        action = "Dragged";
    end
    state = services.workflow.log(state, sprintf( ...
        '%s crop center for image %d: x=%.1f, y=%.1f.', ...
        char(action), currentIndex(state), state.project.inputs.items( ...
        currentIndex(state)).centerXY));
end

function state = initializeCropSizeDefaultsIfNeeded(state)
    if state.session.workflow.cropDefaultsInitialized || ~hasCurrentImage(state)
        return;
    end
    imageData = currentItem(state).image;
    % Constant: the legacy workflow starts with a crop spanning 70% of the
    % source so users can reposition it without immediately hitting bounds.
    defaultCropFraction = 0.7;
    state.project.parameters.cropWidth = max(1, ...
        round(size(imageData, 2) * defaultCropFraction));
    state.project.parameters.cropHeight = max(1, ...
        round(size(imageData, 1) * defaultCropFraction));
    state.session.workflow.cropDefaultsInitialized = true;
end

function [state, ok] = ensureCurrentReady(state, services)
    [state, loaded] = ensureCurrentImageLoaded(state, services);
    ok = loaded && hasCurrentImage(state);
    if ok
        state = ensureCurrentCenter(state);
        state = initializeCropSizeDefaultsIfNeeded(state);
    end
end

function [state, loaded] = ensureCurrentImageLoaded(state, services)
    loaded = false;
    index = currentIndex(state);
    if index < 1 || index > numel(state.project.inputs.items)
        return;
    end
    try
        if index <= numel(state.session.cache.images) && ...
                ~isempty(state.session.cache.images{index})
            loaded = true;
            return;
        end
        loadedItems = batch_crop.sourceFiles.readItems( ...
        sourcePath(state.project.inputs.items(index), ...
        state.project.inputs.sources));
        if isempty(loadedItems)
            error('labkit_BatchImageCrop_app:ImageNotLoaded', ...
                'No image was loaded for item %d.', index);
        end
        state.session.cache.images{index} = loadedItems(1).image;
        loaded = true;
    catch ME
        services.diagnostics.report('Could not load image', ME);
        state = services.workflow.log(state, sprintf( ...
            'Could not load image %d: %s', index, ME.message));
    end
end

function state = ensureCurrentCenter(state)
    if ~hasCurrentImage(state)
        return;
    end
    item = currentItem(state);
    center = item.centerXY;
    if isempty(center) || any(~isfinite(center))
        center = batch_crop.cropGeometry.sourceCenterXY(item.image);
    end
    state = setCurrentCenter(state, center, item.centerSet);
end

function state = setCurrentCenter(state, center, confirmed)
    index = currentIndex(state);
    [geometry, ~] = currentGeometryAndPlacement(state);
    center = batch_crop.cropGeometry.clampCropCenterToCanvas( ...
        geometry, center, batch_crop.cropGeometry.currentCropSize(state));
    state.project.inputs.items(index).centerXY = center;
    state.project.inputs.items(index).centerSet = logical(confirmed);
end

function [geometry, placement] = currentGeometryAndPlacement(state)
    item = currentItem(state);
    [geometry, ~] = batch_crop.cropGeometry.currentGeometry( ...
        state.session.cache.canvas, currentIndex(state), item, ...
        batch_crop.cropGeometry.itemPaddingPercent(item, 0));
    placement = struct("offset", [0 0], ...
        "xData", [1 size(geometry.canvas, 2)], ...
        "yData", [1 size(geometry.canvas, 1)]);
end

function state = clearExportAndCanvas(state)
    state = clearExport(state);
    state.session.cache.canvas = batch_crop.cropGeometry.emptyCanvasCache();
end

function state = clearExport(state)
    state.project.results.lastExport = [];
    state.project.results.lastExportFingerprint = "";
    state.project.results.resultManifestPath = "";
end

function item = currentItem(state)
    index = currentIndex(state);
    item = batch_crop.sourceFiles.workingItems( ...
        state.project.inputs.items(index), state.session.cache.images(index), ...
        state.project.inputs.sources);
end

function index = currentIndex(state)
    index = state.session.selection.currentIndex;
end

function tf = hasCurrentImage(state)
    index = currentIndex(state);
    tf = ~isempty(state.project.inputs.items) && index >= 1 && ...
        index <= numel(state.project.inputs.items) && ...
        index <= numel(state.session.cache.images) && ...
        ~isempty(state.session.cache.images{index});
end

function index = selectedAddedIndex(items, sources, added)
    index = 1;
    if isempty(items)
        index = 0;
        return;
    end
    if isempty(added)
        return;
    end
    source = find(labkit.ui.runtime.sourcePaths(sources) == ...
        added(1), 1, 'first');
    match = [];
    if ~isempty(source)
        match = find(string({items.sourceId}) == string(sources(source).id), ...
            1, 'first');
    end
    if ~isempty(match)
        index = match;
    end
end

function sources = sourcesForTasks(tasks, existingSources)
    sources = labkit.ui.runtime.emptySourceRecords();
    taskIds = unique(string({tasks.sourceId}), 'stable');
    for k = 1:numel(taskIds)
        match = find(string({existingSources.id}) == taskIds(k), 1, 'first');
        if ~isempty(match)
            sources(end + 1) = existingSources(match);
        end
    end
end

function path = sourcePath(task, sources)
    path = "";
    match = find(string({sources.id}) == string(task.sourceId), 1, 'first');
    if ~isempty(match)
        path = labkit.ui.runtime.sourcePaths(sources(match));
    end
end

function cal = calibrationFrom(value)
    cal = labkit.ui.interaction.scaleBarCalibration( ...
        value.referencePixels, value.referenceLength, value.unit, ...
        struct("referenceLine", value.referenceLine, ...
        "defaultUnit", "um"));
end

function value = finiteScalar(candidate, fallback)
    value = fallback;
    if isnumeric(candidate) && isscalar(candidate) && isfinite(double(candidate))
        value = double(candidate);
    end
end

function value = positiveInteger(candidate, fallback)
    value = max(1, round(finiteScalar(candidate, fallback)));
end

function value = positiveScalar(candidate, fallback)
    value = finiteScalar(candidate, fallback);
    if value <= 0
        value = fallback;
    end
end

function value = nonnegativeScalar(candidate, fallback)
    value = finiteScalar(candidate, fallback);
    if value < 0
        value = fallback;
    end
end

function value = positiveOrNaN(candidate)
    value = NaN;
    if isnumeric(candidate) && isscalar(candidate) && ...
            isfinite(double(candidate)) && double(candidate) > 0
        value = double(candidate);
    end
end

function showError(services, titleText, message)
    services.dialogs.alert(message, titleText);
end

function target = mergeActions(target, source)
    names = fieldnames(source);
    for k = 1:numel(names)
        target.(names{k}) = source.(names{k});
    end
end
