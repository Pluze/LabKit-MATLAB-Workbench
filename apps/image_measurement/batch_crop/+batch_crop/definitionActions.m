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
        "exportSettingChanged", @onExportSettingChanged, ...
        "chooseOutputFolder", @onChooseOutputFolder, ...
        "previewPointerDown", @onPreviewPointerDown, ...
        "cropRectangleMoved", @onCropRectangleMoved, ...
        "exportCrops", @onExportCrops);
end

function state = onImagesChosen(state, event, services)
    added = eventPaths(event, "addedFiles");
    paths = eventPaths(event, "files");
    if isempty(paths)
        paths = added;
    end
    if isempty(paths)
        state = addLog(state, services, "Image file selection cancelled.");
        return;
    end
    chosen = batch_crop.appState.itemsForPaths(paths);
    state.project.inputs.items = batch_crop.appState.mergeChosenItems( ...
        state.project.inputs.items, chosen);
    state.project.inputs.sources = sourcesForItems(state.project.inputs.items);
    state.session.selection.currentIndex = selectedAddedIndex( ...
        state.project.inputs.items, added);
    state.project.parameters.outputFolder = string( ...
        labkit.ui.runtime.defaultOutputFolder(paths, "batch_crop", ...
        state.project.parameters.outputFolder));
    state = clearExportAndCanvas(state);
    [state, loaded] = ensureCurrentImageLoaded(state, services);
    if loaded
        state = ensureCurrentCenter(state);
        state = initializeCropSizeDefaultsIfNeeded(state);
    end
    state = addLog(state, services, sprintf( ...
        'Selected %d image file(s); crop tasks: %d.', ...
        numel(paths), numel(state.project.inputs.items)));
end

function state = onClearImages(state, ~, services)
    state.project.inputs.items = repmat(batch_crop.appState.emptyItem(), 0, 1);
    state.project.inputs.sources = emptySources();
    state.session.selection.currentIndex = 0;
    state.session.workflow.cropDefaultsInitialized = false;
    state.session.workflow.scaleReferenceEditing = false;
    state.session.view.scaleBar = [];
    state = clearExportAndCanvas(state);
    state = addLog(state, services, "Cleared loaded images.");
end

function state = onRemoveImages(state, event, services)
    items = state.project.inputs.items;
    indices = eventIndices(event, "removedFiles", numel(items));
    if isempty(indices)
        return;
    end
    items(indices) = [];
    state.project.inputs.items = items;
    state.project.inputs.sources = sourcesForItems(items);
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
    state = addLog(state, services, sprintf( ...
        'Removed %d crop task(s); remaining: %d.', ...
        numel(indices), numel(items)));
end

function state = onDuplicateImage(state, ~, services)
    [state, ok] = ensureCurrentReady(state, services);
    if ~ok
        return;
    end
    index = currentIndex(state);
    duplicate = batch_crop.appState.duplicateItem( ...
        state.project.inputs.items(index));
    insertAt = index + 1;
    items = state.project.inputs.items;
    state.project.inputs.items = [items(1:index); duplicate; items(insertAt:end)];
    state.session.selection.currentIndex = insertAt;
    state.session.workflow.scaleReferenceEditing = false;
    state.session.view.scaleBar = [];
    state = clearExportAndCanvas(state);
    state = ensureCurrentCenter(state);
    state = addLog(state, services, sprintf( ...
        'Duplicated image %d as crop task %d. Pick a new crop center.', ...
        index, insertAt));
end

function state = onImageSelectionChanged(state, event, services)
    indices = eventIndices(event, "selectedFiles", ...
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
    state = addLog(state, services, sprintf( ...
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
    state = addLog(state, services, sprintf( ...
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
    state = addLog(state, services, sprintf( ...
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
    item = state.project.inputs.items(index);
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
    state = addLog(state, services, sprintf( ...
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
    if ~batch_crop.appState.isScaleCalibrationSet(item.scaleCalibration)
        showError(services, 'Calibration required', ...
            ['Measure or enter reference pixels, then enter a positive ' ...
            'reference length and unit.']);
        return;
    end
    try
        state.session.view.scaleBar = batch_crop.userInterface.scaleBarGeometry( ...
            size(item.image), item.scaleCalibration, ...
            state.project.parameters.scaleBarLength, ...
            state.project.parameters.scaleBarPosition, ...
            state.project.parameters.scaleBarColor);
        state.session.workflow.scaleReferenceEditing = false;
    catch ME
        showError(services, 'Could not place scale bar', ME.message);
    end
end

function state = onExportSettingChanged(state, ~, ~)
    state = clearExport(state);
end

function state = onChooseOutputFolder(state, ~, services)
    promptArgs = {};
    if isstruct(services.request) && ...
            isfield(services.request, 'outputFolderChooser') && ...
            isa(services.request.outputFolderChooser, 'function_handle')
        promptArgs = {'Chooser', services.request.outputFolderChooser};
    end
    [folder, cancelled] = labkit.ui.runtime.promptOutputFolder( ...
        'Select crop export folder', ...
        state.project.parameters.outputFolder, promptArgs{:});
    if cancelled
        state = addLog(state, services, "Export folder selection cancelled.");
        return;
    end
    state.project.parameters.outputFolder = string(folder);
    state = clearExport(state);
end

function state = onPreviewPointerDown(state, event, services)
    [state, ok] = ensureCurrentReady(state, services);
    if ~ok || isempty(event.value) || numel(event.value) < 2
        return;
    end
    [geometry, placement] = currentGeometryAndPlacement(state);
    canvas = double(event.value(1:2)) - placement.offset;
    canvas(1) = min(max(canvas(1), 1), size(geometry.canvas, 2));
    canvas(2) = min(max(canvas(2), 1), size(geometry.canvas, 1));
    center = batch_crop.cropGeometry.canvasToOriginal(geometry, canvas);
    state = setCurrentCenter(state, center, true);
    state = clearExport(state);
    state = addLog(state, services, sprintf( ...
        'Picked crop center for image %d: x=%.1f, y=%.1f.', ...
        currentIndex(state), state.project.inputs.items( ...
        currentIndex(state)).centerXY));
end

function state = onCropRectangleMoved(state, event, services)
    [state, ok] = ensureCurrentReady(state, services);
    if ~ok || isempty(event.value) || numel(event.value) ~= 4
        return;
    end
    position = double(event.value);
    [geometry, placement] = currentGeometryAndPlacement(state);
    canvas = [position(1) + position(3) / 2, ...
        position(2) + position(4) / 2] - placement.offset;
    center = batch_crop.cropGeometry.canvasToOriginal(geometry, canvas);
    state = setCurrentCenter(state, center, true);
    state = clearExport(state);
    state = addLog(state, services, sprintf( ...
        'Dragged crop center for image %d: x=%.1f, y=%.1f.', ...
        currentIndex(state), state.project.inputs.items( ...
        currentIndex(state)).centerXY));
end

function state = onExportCrops(state, ~, services)
    items = state.project.inputs.items;
    if isempty(items)
        showError(services, 'No images loaded', ...
            'Load images before exporting crops.');
        return;
    end
    if ~all([items.centerSet])
        showError(services, 'Crop centers missing', ...
            batch_crop.userInterface.missingWorkflowItemsText(items, "center"));
        return;
    end
    if strcmpi(state.project.parameters.scaleMode, "Physical") && ...
            ~batch_crop.appState.scaleCalibrationSummary(items).allCalibrated
        showError(services, 'Scale calibration missing', ...
            batch_crop.userInterface.missingWorkflowItemsText(items, "scale"));
        return;
    end
    [state, loaded] = ensureAllImagesLoaded(state, services);
    if ~loaded
        return;
    end
    opts = currentExportOptions(state);
    plan = batch_crop.appState.exportPlan(state.project.inputs.items, opts);
    results = state.project.results;
    if ~isempty(results.lastExport) && ...
            results.lastExportFingerprint == plan.fingerprint
        state = addLog(state, services, ...
            "Crop export is already up to date; skipped duplicate write.");
        return;
    end
    try
        payload = batch_crop.resultFiles.writeOutputs( ...
            state.project.inputs.items, opts);
        spec = standardResultSpec(state, payload);
        [manifestPath, ~] = services.results.writeManifest( ...
            opts.outputFolder, spec);
    catch ME
        reportException(services, 'Export failed', ME);
        showError(services, 'Export failed', ME.message);
        return;
    end
    payload.resultManifestPath = string(manifestPath);
    state.project.results.lastExport = payload;
    state.project.results.lastExportFingerprint = plan.fingerprint;
    state.project.results.resultManifestPath = string(manifestPath);
    statuses = string({payload.results.status});
    savedCount = sum(statuses == "saved");
    failedCount = sum(statuses == "failed");
    state = addLog(state, services, sprintf( ...
        'Exported %d crop(s), %d failed. Manifest: %s', ...
        savedCount, failedCount, char(payload.manifestPath)));
    if failedCount > 0
        showError(services, 'Some crops failed', sprintf( ...
            '%d image(s) failed. See the manifest for details.', failedCount));
    end
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
        [state.project.inputs.items, loaded] = ...
            batch_crop.appState.loadImageForIndex( ...
            state.project.inputs.items, index);
    catch ME
        reportException(services, 'Could not load image', ME);
        state = addLog(state, services, sprintf( ...
            'Could not load image %d: %s', index, ME.message));
    end
end

function [state, loaded] = ensureAllImagesLoaded(state, services)
    loaded = false;
    try
        state.project.inputs.items = batch_crop.appState.loadMissingImages( ...
            state.project.inputs.items);
        state.session.cache.canvas = batch_crop.appState.emptyCanvasCache();
        loaded = true;
    catch ME
        reportException(services, 'Could not load image', ME);
        showError(services, 'Could not load image', ME.message);
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
        geometry, center, currentCropSize(state));
    state.project.inputs.items(index).centerXY = center;
    state.project.inputs.items(index).centerSet = logical(confirmed);
end

function [geometry, placement] = currentGeometryAndPlacement(state)
    item = currentItem(state);
    [geometry, ~] = batch_crop.appState.currentGeometry( ...
        state.session.cache.canvas, currentIndex(state), item, ...
        batch_crop.appState.itemPaddingPercent(item, 0));
    placement = struct("offset", [0 0], ...
        "xData", [1 size(geometry.canvas, 2)], ...
        "yData", [1 size(geometry.canvas, 1)]);
end

function sizeValue = currentCropSize(state)
    parameters = state.project.parameters;
    if strcmpi(parameters.scaleMode, "Physical") && hasCurrentImage(state)
        cal = currentItem(state).scaleCalibration;
        if batch_crop.appState.isScaleCalibrationSet(cal)
            pixelsPerUnit = batch_crop.cropGeometry.pixelsPerUnitForUnit( ...
                cal, parameters.scaleUnit);
            sizeValue = max(1, round([parameters.physicalWidth, ...
                parameters.physicalHeight] * pixelsPerUnit));
            return;
        end
    end
    sizeValue = max(1, round([parameters.cropWidth, parameters.cropHeight]));
end

function opts = currentExportOptions(state)
    parameters = state.project.parameters;
    padding = 0;
    if hasCurrentImage(state)
        padding = currentItem(state).paddingPercent;
    end
    opts = batch_crop.appState.exportOptions( ...
        parameters.outputFolder, parameters.format, currentCropSize(state), ...
        padding, parameters.scaleMode, parameters.scaleUnit, ...
        [parameters.physicalWidth, parameters.physicalHeight], ...
        parameters.targetPixelsPerUnit, parameters.maxUpsamplePercent);
end

function spec = standardResultSpec(state, payload)
    cropOutputs = repmat(resultOutput("", "", "", "", "", ""), ...
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
        cropOutputs(k) = resultOutput("crop" + string(k), "primary", ...
            string(name) + string(extension), mediaType(extension), status, ...
            string(result.message));
    end
    [~, csvName, csvExtension] = fileparts(payload.manifestPath);
    csvOutput = resultOutput("cropManifest", "manifest", ...
        string(csvName) + string(csvExtension), "text/csv", "success", "");
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

function output = resultOutput(id, role, pathValue, type, status, message)
    output = struct("Id", string(id), "Role", string(role), ...
        "Path", string(pathValue), "MediaType", string(type), ...
        "Status", string(status), "Message", string(message));
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

function state = clearExportAndCanvas(state)
    state = clearExport(state);
    state.session.cache.canvas = batch_crop.appState.emptyCanvasCache();
end

function state = clearExport(state)
    state.project.results.lastExport = [];
    state.project.results.lastExportFingerprint = "";
    state.project.results.resultManifestPath = "";
end

function item = currentItem(state)
    item = state.project.inputs.items(currentIndex(state));
end

function index = currentIndex(state)
    index = state.session.selection.currentIndex;
end

function tf = hasCurrentImage(state)
    index = currentIndex(state);
    tf = ~isempty(state.project.inputs.items) && index >= 1 && ...
        index <= numel(state.project.inputs.items) && ...
        ~isempty(state.project.inputs.items(index).image);
end

function index = selectedAddedIndex(items, added)
    index = 1;
    if isempty(items)
        index = 0;
        return;
    end
    if isempty(added)
        return;
    end
    match = find(string({items.path}) == added(1), 1, 'first');
    if ~isempty(match)
        index = match;
    end
end

function indices = eventIndices(event, fieldName, count)
    entries = eventEntries(event, fieldName);
    indices = zeros(0, 1);
    if isempty(entries)
        return;
    end
    if isstruct(entries) && isfield(entries, 'id')
        ids = string({entries.id});
        values = regexp(ids, '^item(\d+)$', 'tokens', 'once');
        for k = 1:numel(values)
            if ~isempty(values{k})
                indices(end + 1, 1) = str2double(values{k}{1});
            end
        end
    end
    if isempty(indices) && isstruct(entries) && isfield(entries, 'path')
        paths = string({entries.path});
        allPaths = string({event.meta.original.files.path});
        [~, indices] = ismember(paths, allPaths);
    end
    indices = unique(indices(indices >= 1 & indices <= count), 'stable');
end

function paths = eventPaths(event, fieldName)
    values = eventEntries(event, fieldName);
    if isstruct(values) && isfield(values, 'path')
        paths = string({values.path}).';
    else
        paths = string(values(:));
    end
    paths = paths(strlength(paths) > 0);
end

function values = eventEntries(event, fieldName)
    values = [];
    if isfield(event, 'meta') && isstruct(event.meta) && ...
            isfield(event.meta, 'original') && ...
            isfield(event.meta.original, char(fieldName))
        values = event.meta.original.(char(fieldName));
    end
end

function sources = sourcesForItems(items)
    sources = emptySources();
    if isempty(items)
        return;
    end
    paths = unique(string({items.path}), 'stable');
    for k = 1:numel(paths)
        [~, name, extension] = fileparts(paths(k));
        reference = struct("schemaVersion", 1, "relativePath", "", ...
            "originalPath", paths(k), ...
            "fileName", string(name) + string(extension));
        source = struct("id", "image" + string(k), "required", true, ...
            "role", "cropSource", "reference", reference);
        if isempty(sources)
            sources = source;
        else
            sources(end + 1) = source;
        end
    end
end

function sources = emptySources()
    sources = struct("id", {}, "required", {}, "role", {}, ...
        "reference", {});
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
    labkit.ui.runtime.showAlert(services.figure, message, titleText);
end

function state = addLog(state, services, message)
    message = string(message);
    state.session.workflow.logLines(end + 1, 1) = message;
    if isstruct(services.debug) && isfield(services.debug, 'enabled') && ...
            logical(services.debug.enabled)
        services.debug.append(char(message));
    end
end

function reportException(services, context, exception)
    if isstruct(services.debug) && isfield(services.debug, 'reportException')
        services.debug.reportException('batchCrop', context, exception);
    end
end
