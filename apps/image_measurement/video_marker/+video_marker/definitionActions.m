% App-owned V2 action registry for Video Marker. Handlers receive canonical
% state/events/services and own durable skeleton/annotation edits, lazy video
% resources, frame navigation, scale calibration, and standard result exports.
function actions = definitionActions()
    actions = struct( ...
        "openVideo", @onOpenVideo, ...
        "frameChanged", @onFrameChanged, ...
        "previousFrame", @onPreviousFrame, ...
        "nextFrame", @onNextFrame, ...
        "pointsEdited", @onPointsEdited, ...
        "undoPoint", @onUndoPoint, ...
        "clearFramePoints", @onClearFramePoints, ...
        "measureScaleReference", @onMeasureScaleReference, ...
        "scaleReferenceEdited", @onScaleReferenceEdited, ...
        "scaleCalibrationChanged", @onScaleCalibrationChanged, ...
        "scaleBarSettingChanged", @onScaleBarSettingChanged, ...
        "placeScaleBar", @onPlaceScaleBar, ...
        "importMarkerCsv", @onImportMarkerCsv, ...
        "exportMarkerCsv", @onExportMarkerCsv, ...
        "exportSettingChanged", @onExportSettingChanged, ...
        "exportCoordinateCsv", @onExportCoordinateCsv, ...
        "saveAutosave", @onSaveAutosave, ...
        "newSetup", @onNewSetup);
    actions = mergeActions(actions, ...
        video_marker.skeletonSetup.definitionActions());
end

function state = onOpenVideo(state, event, services)
    paths = services.events.paths(event, "addedFiles");
    if isempty(paths)
        paths = services.events.paths(event, "files");
    end
    if isempty(paths)
        state = services.workflow.log(state, "Video selection cancelled.");
        return;
    end
    if isempty(state.project.annotations.skeleton.pointNames)
        showError(services, 'Skeleton required', ...
            'Add and name at least one keypoint before opening a video.');
        return;
    end
    try
        resource = openVideoResource(paths(1));
        firstFrame = resource.cache.readFrame(1);
        resource.cache.reset(1, firstFrame);
        setVideoResource(services, resource);
    catch ME
        services.diagnostics.report('Could not open video', ME);
        showError(services, 'Could not open video', ME.message);
        return;
    end
    state.project.inputs.sources = services.project.sourceRecord( ...
        "video", "video", paths(1), true);
    state.project.inputs.videoMetadata = ...
        video_marker.videoSource.metadataFromInfo(resource.info);
    pointCount = numel(state.project.annotations.skeleton.pointIds);
    state.project.annotations.frames = ...
        video_marker.frameAnnotations.emptyAnnotations( ...
        resource.info.frameCount, pointCount);
    state.project.annotations.calibration = ...
        labkit.ui.interaction.scaleBarCalibration([], [], "um");
    state.project.parameters.coordinateStartFrame = 1;
    state.project.parameters.coordinateEndFrame = resource.info.frameCount;
    state.session.selection.currentFrame = 1;
    state.session.selection.selectedPointIndex = 0;
    state.session.selection.selectedEdgeIndex = 0;
    state.session.workflow.scaleReferenceEditing = false;
    state.session.workflow.statusMessage = "Video opened.";
    state.session.view.scaleBar = [];
    state.session.cache.videoInfo = resource.info;
    state.session.cache.currentImage = firstFrame;
    state.session.cache.frameIndex = 1;
    state = clearResults(state);
    state = services.workflow.log(state, "Opened video: " + paths(1));
end

function state = onFrameChanged(state, event, services)
    target = event.value;
    if isempty(target)
        target = state.session.selection.currentFrame;
    end
    state = goToFrame(state, target, services);
end

function state = onPreviousFrame(state, ~, services)
    state = goToFrame(state, state.session.cache.frameIndex - 1, services);
end

function state = onNextFrame(state, ~, services)
    state = goToFrame(state, state.session.cache.frameIndex + 1, services);
end

function state = goToFrame(state, target, services)
    info = state.session.cache.videoInfo;
    if info.frameCount <= 0 || isempty(state.session.cache.currentImage)
        return;
    end
    target = min(max(1, round(finiteScalar(target, ...
        state.session.cache.frameIndex))), info.frameCount);
    startFrame = state.session.cache.frameIndex;
    if target == startFrame
        state.session.selection.currentFrame = target;
        return;
    end
    try
        resource = ensureVideoResource(state, services);
        [frames, imageData, report] = ...
            video_marker.frameNavigation.loadTargetFrame( ...
            resource.cache.readFrame, state.project.annotations.frames, ...
            startFrame, target, state.session.cache.currentImage, ...
            numel(state.project.annotations.skeleton.pointIds));
    catch ME
        services.diagnostics.report('Could not read frame', ME);
        showError(services, 'Could not read frame', ME.message);
        state.session.selection.currentFrame = startFrame;
        return;
    end
    if frames.frameStatus(target) == ...
            video_marker.frameAnnotations.statusCode("empty")
        frames = video_marker.frameAnnotations.inheritDraft(frames, target);
    end
    state.project.annotations.frames = frames;
    state.session.selection.currentFrame = target;
    state.session.cache.currentImage = imageData;
    state.session.cache.frameIndex = target;
    state.session.workflow.scaleReferenceEditing = false;
    state.session.view.scaleBar = [];
    state = clearResults(state);
    if report.predictedFrames > 0
        message = sprintf(['Predicted %d frame(s) through frame %d; ' ...
            '%d point(s) used motion fallback.'], ...
            report.predictedFrames, target, report.fallbackPoints);
    else
        message = sprintf('Moved to frame %d.', target);
    end
    state = services.workflow.log(state, message);
end

function state = onPointsEdited(state, event, services)
    if ~hasVideo(state)
        return;
    end
    points = double(event.value);
    if isempty(points)
        points = zeros(0, 2);
    elseif size(points, 2) ~= 2
        return;
    end
    total = numel(state.project.annotations.skeleton.pointIds);
    if size(points, 1) > total
        points = points(1:total, :);
    end
    status = "draft";
    if size(points, 1) == total
        status = "confirmed";
    end
    frame = state.session.cache.frameIndex;
    state.project.annotations.frames = ...
        video_marker.frameAnnotations.setFramePoints( ...
        state.project.annotations.frames, frame, points, status, ...
        "manual", ones(size(points, 1), 1));
    state = clearResults(state);
    state = services.workflow.log(state, sprintf( ...
        'Frame %d points: %d / %d.', frame, size(points, 1), total));
end

function state = onUndoPoint(state, ~, services)
    points = currentPoints(state);
    if isempty(points)
        return;
    end
    points(end, :) = [];
    state = setCurrentPoints(state, points);
    state = services.workflow.log(state, sprintf( ...
        'Undid last point on frame %d.', state.session.cache.frameIndex));
end

function state = onClearFramePoints(state, ~, services)
    if ~hasVideo(state)
        return;
    end
    state = setCurrentPoints(state, zeros(0, 2));
    state = services.workflow.log(state, sprintf( ...
        'Cleared frame %d points.', state.session.cache.frameIndex));
end

function state = setCurrentPoints(state, points)
    total = numel(state.project.annotations.skeleton.pointIds);
    status = "draft";
    if isempty(points)
        status = "empty";
    elseif size(points, 1) == total
        status = "confirmed";
    end
    state.project.annotations.frames = ...
        video_marker.frameAnnotations.setFramePoints( ...
        state.project.annotations.frames, state.session.cache.frameIndex, ...
        points, status, "manual", ones(size(points, 1), 1));
    state = clearResults(state);
end

function state = onMeasureScaleReference(state, ~, services)
    if ~hasVideo(state)
        showError(services, 'No video loaded', ...
            'Open a video before measuring reference pixels.');
        return;
    end
    state.session.workflow.scaleReferenceEditing = ...
        ~state.session.workflow.scaleReferenceEditing;
    state.session.view.scaleBar = [];
end

function state = onScaleReferenceEdited(state, event, ~)
    points = double(event.value);
    if isempty(points)
        points = zeros(0, 2);
    elseif size(points, 2) ~= 2
        return;
    end
    calibration = state.project.annotations.calibration;
    state.project.annotations.calibration = ...
        labkit.ui.interaction.scaleBarCalibration( ...
        NaN, calibration.referenceLength, calibration.unit, ...
        struct("referenceLine", points));
    state.session.view.scaleBar = [];
    state = clearResults(state);
end

function state = onScaleCalibrationChanged(state, event, ~)
    calibration = state.project.annotations.calibration;
    referencePixels = calibration.referencePixels;
    referenceLength = calibration.referenceLength;
    unit = calibration.unit;
    referenceLine = calibration.referenceLine;
    if event.target == "scaleReferencePixels"
        referencePixels = positiveOrNaN(event.value);
        referenceLine = zeros(0, 2);
    elseif event.target == "scaleReferenceLength"
        referenceLength = nonnegativeScalar(event.value, referenceLength);
    elseif event.target == "scaleCalibrationUnit"
        unit = string(event.value);
    end
    state.project.annotations.calibration = ...
        labkit.ui.interaction.scaleBarCalibration( ...
        referencePixels, referenceLength, unit, ...
        struct("referenceLine", referenceLine));
    state.session.view.scaleBar = [];
    state = clearResults(state);
end

function state = onScaleBarSettingChanged(state, ~, ~)
    state.project.parameters.scaleBarLength = nonnegativeScalar( ...
        state.project.parameters.scaleBarLength, 0);
    state.session.view.scaleBar = [];
end

function state = onPlaceScaleBar(state, ~, services)
    calibration = state.project.annotations.calibration;
    if ~hasVideo(state) || ~calibration.isCalibrated
        showError(services, 'Calibration required', ...
            ['Measure or enter reference pixels, then enter a positive ' ...
            'reference length and unit.']);
        return;
    end
    try
        state.session.view.scaleBar = ...
            labkit.ui.interaction.scaleBarGeometry( ...
            size(state.session.cache.currentImage), calibration, ...
            state.project.parameters.scaleBarLength, ...
            state.project.parameters.scaleBarPosition, ...
            state.project.parameters.scaleBarColor);
        state.session.workflow.scaleReferenceEditing = false;
    catch ME
        services.diagnostics.report('Could not place scale bar', ME);
        showError(services, 'Could not place scale bar', ME.message);
    end
end

function state = onImportMarkerCsv(state, ~, services)
    [filepath, cancelled] = services.dialogs.inputFile( ...
        {'*.csv', 'Marker CSV'}, 'Import marker CSV', ...
        services.dialogs.defaultFolder("input"));
    if cancelled
        state = services.workflow.log(state, "Marker CSV import cancelled.");
        return;
    end
    try
        payload = video_marker.markerCsv.readFile(filepath);
    catch ME
        services.diagnostics.report('Could not import marker CSV', ME);
        showError(services, 'Could not import marker CSV', ME.message);
        return;
    end
    state.project.annotations.skeleton = payload.skeleton;
    state.project.annotations.frames = payload.annotations;
    state.project.annotations.calibration = payload.calibration;
    state.project.inputs.videoMetadata = ...
        video_marker.videoSource.metadataFromInfo(payload.videoInfo);
    state = video_marker.skeletonSetup.normalizeSelection(state, true);
    state.session.workflow.scaleReferenceEditing = false;
    state.session.view.scaleBar = [];
    pathValue = string(payload.videoInfo.path);
    if strlength(pathValue) > 0
        required = isfile(pathValue);
        state.project.inputs.sources = services.project.sourceRecord( ...
            "video", "video", pathValue, required);
    else
        state.project.inputs.sources = state.project.inputs.sources([]);
    end
    if isfile(pathValue)
        try
            resource = openVideoResource(pathValue);
            verifyImportedShape(payload.annotations, payload.skeleton, resource.info);
            imageData = resource.cache.readFrame(1);
            resource.cache.reset(1, imageData);
            setVideoResource(services, resource);
            state.session.cache.videoInfo = resource.info;
            state.session.cache.currentImage = imageData;
            state.session.cache.frameIndex = 1;
            state.session.selection.currentFrame = 1;
        catch ME
            services.diagnostics.report('Could not reopen marker CSV video', ME);
            state.session.cache.videoInfo = payload.videoInfo;
            state.session.cache.currentImage = [];
        end
    else
        state.session.cache.videoInfo = payload.videoInfo;
        state.session.cache.currentImage = [];
    end
    state.project.parameters.coordinateStartFrame = 1;
    state.project.parameters.coordinateEndFrame = ...
        max(1, payload.videoInfo.frameCount);
    state = clearResults(state);
    state = services.workflow.log(state, "Imported marker CSV: " + filepath);
end

function state = onExportMarkerCsv(state, ~, services)
    if ~hasVideo(state)
        showError(services, 'No video loaded', ...
            'Open a video before exporting marker CSV.');
        return;
    end
    [filepath, cancelled] = services.dialogs.outputFile( ...
        {'*.csv', 'Marker CSV'}, 'Export marker CSV', ...
        fullfile(defaultOutputFolder(state, services), ...
        'video_marker_markers.csv'));
    if cancelled
        state = services.workflow.log(state, "Marker CSV export cancelled.");
        return;
    end
    try
        video_marker.markerCsv.writeFile(filepath, ...
            state.project.annotations.frames, ...
            state.project.annotations.skeleton, ...
            state.session.cache.videoInfo, ...
            state.project.annotations.calibration);
        manifestPath = writeResultManifest(state, services, filepath, ...
            "markerCsv", "text/csv", "video_marker_markers.labkit.json");
    catch ME
        services.diagnostics.report('Could not export marker CSV', ME);
        showError(services, 'Could not export marker CSV', ME.message);
        return;
    end
    state.project.results.markerManifestPath = string(manifestPath);
    state = services.workflow.log(state, "Exported marker CSV: " + filepath);
end

function state = onExportSettingChanged(state, ~, ~)
    count = max(1, state.session.cache.videoInfo.frameCount);
    state.project.parameters.coordinateStartFrame = min(max(1, round( ...
        finiteScalar(state.project.parameters.coordinateStartFrame, 1))), count);
    state.project.parameters.coordinateEndFrame = min(max(1, round( ...
        finiteScalar(state.project.parameters.coordinateEndFrame, count))), count);
    state.project.results.coordinateManifestPath = "";
end

function state = onExportCoordinateCsv(state, ~, services)
    if ~hasVideo(state)
        showError(services, 'No video loaded', ...
            'Open a video before exporting coordinate CSV.');
        return;
    end
    parameters = state.project.parameters;
    opts = video_marker.coordinateExport.options( ...
        "startFrame", parameters.coordinateStartFrame, ...
        "endFrame", parameters.coordinateEndFrame, ...
        "unitMode", parameters.coordinateUnitMode, ...
        "originMode", parameters.coordinateOriginMode, ...
        "yAxisMode", parameters.coordinateYAxisMode);
    [filepath, cancelled] = services.dialogs.outputFile( ...
        {'*.csv', 'Coordinate CSV'}, 'Export coordinate CSV', ...
        fullfile(defaultOutputFolder(state, services), ...
        'video_marker_coordinates.csv'));
    if cancelled
        state = services.workflow.log(state, "Coordinate CSV export cancelled.");
        return;
    end
    try
        tableData = video_marker.coordinateExport.buildTable( ...
            state.project.annotations.frames, ...
            state.project.annotations.skeleton, ...
            state.session.cache.videoInfo, ...
            state.project.annotations.calibration, opts);
        writetable(tableData, filepath);
        manifestPath = writeResultManifest(state, services, filepath, ...
            "coordinateCsv", "text/csv", ...
            "video_marker_coordinates.labkit.json");
    catch ME
        services.diagnostics.report('Could not export coordinate CSV', ME);
        showError(services, 'Could not export coordinate CSV', ME.message);
        return;
    end
    state.project.results.coordinateManifestPath = string(manifestPath);
    state = services.workflow.log(state, ...
        "Exported coordinate CSV: " + filepath);
end

function state = onSaveAutosave(state, ~, services)
    videoPath = labkit.ui.runtime.sourcePaths( ...
        state.project.inputs.sources, "video");
    if strlength(videoPath) == 0
        state = services.workflow.log(state, ...
            "Autosave unavailable until a video is open.");
        return;
    end
    try
        filepath = video_marker.autosave.filePath(videoPath);
        state.project.inputs.videoMetadata = ...
            video_marker.videoSource.metadataFromInfo( ...
            state.session.cache.videoInfo);
        services.project.saveAutosave(state, filepath);
    catch ME
        services.diagnostics.report('Could not save Video Marker autosave', ME);
        services.dialogs.alert(ME.message, 'Could not save autosave');
        state = services.workflow.log(state, "Autosave failed: " + ME.message);
        return;
    end
    state = services.workflow.log(state, "Autosave updated: " + filepath);
end

function state = onNewSetup(state, ~, services)
    choices = video_marker.userInterface.sessionChoices();
    answer = services.dialogs.choice( ...
        ['Starting a new setup clears the current video, skeleton, and ' ...
        'annotations. Saving the current project first is recommended.'], ...
        'Start a new setup?', ...
        [choices.cancel, choices.saveAndStart, choices.discardAndStart], ...
        choices.saveAndStart, choices.cancel);
    if answer == choices.cancel || strlength(answer) == 0
        state = services.workflow.log(state, "New setup cancelled.");
        return;
    end
    if answer == choices.saveAndStart
        filepath = services.project.saveState();
        if strlength(filepath) == 0
            state = services.workflow.log(state, ...
                "New setup cancelled because project save was cancelled.");
            return;
        end
    elseif answer ~= choices.discardAndStart
        state = services.workflow.log(state, "New setup cancelled.");
        return;
    end
    services.resources.clearScope("session");
    state = services.project.newState();
    state = services.workflow.log(state, ...
        "Started a new skeleton setup and cleared the annotation session.");
end

function resource = ensureVideoResource(state, services)
    pathValue = labkit.ui.runtime.sourcePaths( ...
        state.project.inputs.sources, "video");
    resource = services.resources.get("session", "video");
    if isstruct(resource) && isscalar(resource) && ...
            isfield(resource, 'path') && resource.path == pathValue
        return;
    end
    resource = openVideoResource(pathValue);
    if ~isempty(state.session.cache.currentImage)
        resource.cache.reset(state.session.cache.frameIndex, ...
            state.session.cache.currentImage);
    end
    setVideoResource(services, resource);
end

function resource = openVideoResource(pathValue)
    [reader, info] = video_marker.videoSource.openVideo(pathValue);
    cache = video_marker.videoSource.createDecodedFrameCache( ...
        @(index) video_marker.videoSource.readFrame(reader, index));
    resource = struct("path", string(pathValue), ...
        "reader", reader, "info", info, "cache", cache);
end

function setVideoResource(services, resource)
    services.resources.set("session", "video", resource);
end

function points = currentPoints(state)
    points = zeros(0, 2);
    if hasVideo(state)
        points = video_marker.frameAnnotations.framePoints( ...
            state.project.annotations.frames, ...
            state.session.cache.frameIndex);
    end
end

function tf = hasVideo(state)
    tf = state.session.cache.videoInfo.frameCount > 0 && ...
        ~isempty(state.session.cache.currentImage);
end

function state = clearResults(state)
    state.project.results.markerManifestPath = "";
    state.project.results.coordinateManifestPath = "";
end

function folder = defaultOutputFolder(state, services)
    videoPath = labkit.ui.runtime.sourcePaths( ...
        state.project.inputs.sources, "video");
    folder = services.dialogs.defaultOutputFolder( ...
        videoPath, "video_marker");
end

function manifestPath = writeResultManifest( ...
        state, services, filepath, id, mediaType, manifestName)
    [folder, name, extension] = fileparts(filepath);
    output = services.results.output(id, "primary", ...
        string(name) + string(extension), mediaType);
    spec = struct( ...
        "Outputs", output, ...
        "Inputs", state.project.inputs.sources, ...
        "Parameters", state.project.parameters, ...
        "Summary", video_marker.frameAnnotations.summary( ...
        state.project.annotations.frames), ...
        "ManifestName", manifestName);
    [manifestPath, ~] = services.results.writeManifest(folder, spec);
end

function verifyImportedShape(frames, skeleton, info)
    if size(frames.coords, 1) ~= info.frameCount || ...
            size(frames.coords, 2) ~= numel(skeleton.pointIds)
        error('video_marker:ImportedShapeMismatch', ...
            'Imported annotations do not match the referenced video.');
    end
end

function showError(services, titleText, message)
    services.dialogs.alert(message, titleText);
end

function value = finiteScalar(value, fallback)
    value = double(value);
    if isempty(value) || ~isscalar(value) || ~isfinite(value)
        value = fallback;
    end
end

function value = nonnegativeScalar(value, fallback)
    value = finiteScalar(value, fallback);
    if value < 0
        value = fallback;
    end
end

function value = positiveOrNaN(value)
    value = finiteScalar(value, NaN);
    if ~isfinite(value) || value <= 0
        value = NaN;
    end
end

function target = mergeActions(target, source)
    names = fieldnames(source);
    for k = 1:numel(names)
        target.(names{k}) = source.(names{k});
    end
end
