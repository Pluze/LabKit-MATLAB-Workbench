% Expected caller: the LabKit V2 runtime. Input is canonical Video Marker
% state. Output is one deterministic control, preview, and controlled-editor
% presentation with no UI registry, graphics handles, or app-owned runtime.
function view = presentWorkbench(state)
    project = state.project;
    session = state.session;
    skeleton = project.annotations.skeleton;
    frames = project.annotations.frames;
    calibration = project.annotations.calibration;
    info = session.cache.videoInfo;
    frameIndex = currentFrame(state);
    hasVideo = info.frameCount > 0 && ~isempty(session.cache.currentImage);
    locked = hasVideo;
    points = currentPoints(state);
    pointCount = numel(skeleton.pointIds);

    view = struct();
    view.controls.skeletonPreset = valueSpec(session.selection.skeletonPreset);
    view.controls.useSkeletonPreset = enabledSpec(~locked);
    view.controls.keypointTable = tableSpec( ...
        keypointTable(skeleton), ~locked);
    view.controls.connectionTable = tableSpec( ...
        connectionTable(skeleton), ~locked);
    view.controls.addKeypoint = enabledSpec(~locked);
    selectedPoint = double(session.selection.selectedPointIndex);
    view.controls.removeKeypoint = enabledSpec(~locked && selectedPoint >= 1);
    view.controls.moveKeypointUp = enabledSpec( ...
        ~locked && selectedPoint > 1);
    view.controls.moveKeypointDown = enabledSpec( ...
        ~locked && selectedPoint >= 1 && selectedPoint < pointCount);
    view = connectionPresentation(view, state, locked);
    view.controls.skeletonStatus = valueSpec(skeletonStatus(locked, pointCount));

    videoPath = video_marker.sourceFiles.pathForId( ...
        project.inputs.sources, "video");
    view.controls.videoFile = fileSpec(videoPath, hasVideo);
    view.controls.saveAutosave = enabledSpec(hasVideo);
    view.controls.videoSummary = valueSpec(videoSummary(info));
    view.controls.currentFrame = struct( ...
        "Value", frameIndex, "Limits", [1 max(2, info.frameCount)], ...
        "Enabled", hasVideo);
    view.controls.previousFrame = enabledSpec(hasVideo && frameIndex > 1);
    view.controls.nextFrame = enabledSpec( ...
        hasVideo && frameIndex < info.frameCount);
    view.controls.undoPoint = enabledSpec(hasVideo && ~isempty(points));
    view.controls.clearFramePoints = enabledSpec(hasVideo && ~isempty(points));
    view.controls.frameStatus = valueSpec(frameStatus( ...
        frames, frameIndex, size(points, 1), pointCount, hasVideo));

    view.controls.importMarkerCsv = enabledSpec(true);
    view.controls.exportMarkerCsv = enabledSpec(hasVideo);
    view.controls.exportCoordinateCsv = enabledSpec(hasVideo);
    view.controls.coordinateStartFrame = rangeSpec( ...
        project.parameters.coordinateStartFrame, info.frameCount, hasVideo);
    view.controls.coordinateEndFrame = rangeSpec( ...
        project.parameters.coordinateEndFrame, info.frameCount, hasVideo);
    view.controls.summaryTable = tableSpec(summaryTable(state), true);
    view = scalePresentation(view, state, hasVideo);

    model = struct( ...
        "imageData", session.cache.currentImage, ...
        "title", frameTitle(frameIndex, hasVideo), ...
        "skeleton", skeleton, ...
        "points", points, ...
        "scaleBar", session.view.scaleBar);
    view.previews.videoAxes.Axes.video = struct( ...
        "Renderer", "videoFrame", "Model", model);
    if hasVideo
        if session.workflow.scaleReferenceEditing
            view.interactions.scaleReference = struct( ...
                "Kind", "scaleBarReference", ...
                "Targets", "videoAxes", ...
                "Value", calibration.referenceLine, ...
                "Event", "scaleReferenceEdited", ...
                "ImageSize", size(session.cache.currentImage), ...
                "ChangePolicy", "commit", ...
                "Options", struct("color", [1 1 0]));
        else
            view.interactions.framePoints = struct( ...
                "Kind", "anchors", ...
                "Targets", "videoAxes", ...
                "Value", points, ...
                "Event", "pointsEdited", ...
                "ImageSize", size(session.cache.currentImage), ...
                "ChangePolicy", "commit", ...
                "Options", struct("mode", "points", ...
                "maxPoints", pointCount, "color", [0 0.85 1]));
        end
    end
end

function view = connectionPresentation(view, state, locked)
    names = string(state.project.annotations.skeleton.pointNames(:));
    enough = numel(names) >= 2;
    from = validChoice(state.session.selection.connectionFrom, names, 1);
    toCandidates = names(names ~= from);
    to = validChoice(state.session.selection.connectionTo, toCandidates, 1);
    if isempty(names)
        names = "Add keypoints first";
        from = names;
        toCandidates = names;
        to = names;
    elseif isempty(toCandidates)
        toCandidates = "Add another keypoint";
        to = toCandidates;
    end
    view.controls.connectionFrom = choiceSpec( ...
        names, from, ~locked && enough);
    view.controls.connectionTo = choiceSpec( ...
        toCandidates, to, ~locked && enough);
    view.controls.addConnection = enabledSpec(~locked && enough);
    view.controls.connectInOrder = enabledSpec(~locked && enough);
    selectedEdge = double(state.session.selection.selectedEdgeIndex);
    view.controls.removeConnection = enabledSpec( ...
        ~locked && selectedEdge >= 1);
end

function view = scalePresentation(view, state, hasVideo)
    calibration = state.project.annotations.calibration;
    editing = state.session.workflow.scaleReferenceEditing;
    referencePixels = calibration.referencePixels;
    referenceReadout = "-";
    if isfinite(referencePixels)
        referenceReadout = sprintf('%.6g', referencePixels);
    else
        referencePixels = 0;
    end
    pixelsReadout = "-";
    if calibration.pixelsPerUnit > 0
        pixelsReadout = sprintf('%.6g px/%s', ...
            calibration.pixelsPerUnit, calibration.unit);
    end
    view.controls.measureScaleReference = struct( ...
        "Enabled", hasVideo, ...
        "Text", ternary(editing, ...
        "Finish reference edit", "Measure reference pixels"));
    view.controls.scaleReferencePixels = controlSpec( ...
        hasVideo && ~editing, referencePixels);
    view.controls.scaleReferenceLength = controlSpec( ...
        hasVideo, calibration.referenceLength);
    view.controls.scaleCalibrationUnit = controlSpec( ...
        hasVideo, calibration.unit);
    view.controls.scaleBarLength = enabledSpec(hasVideo);
    view.controls.scaleBarPosition = enabledSpec(hasVideo);
    view.controls.scaleBarColor = enabledSpec(hasVideo);
    view.controls.placeScaleBar = enabledSpec( ...
        hasVideo && calibration.isCalibrated && ~editing);
    view.controls.scaleReferenceReadout = valueSpec(referenceReadout);
    view.controls.pixelsPerUnitReadout = valueSpec(pixelsReadout);
end

function points = currentPoints(state)
    points = zeros(0, 2);
    frames = state.project.annotations.frames;
    index = currentFrame(state);
    if ~isempty(frames.coords) && index >= 1 && ...
            index <= size(frames.coords, 1)
        points = video_marker.frameAnnotations.framePoints(frames, index);
    end
end

function index = currentFrame(state)
    index = max(1, round(double(state.session.selection.currentFrame)));
    if state.session.cache.videoInfo.frameCount > 0
        index = min(index, state.session.cache.videoInfo.frameCount);
    end
end

function data = keypointTable(skeleton)
    names = cellstr(string(skeleton.pointNames(:)));
    data = cell(numel(names), 2);
    for k = 1:numel(names)
        data{k, 1} = k;
        data{k, 2} = names{k};
    end
end

function data = connectionTable(skeleton)
    edges = skeleton.edges;
    names = string(skeleton.pointNames(:));
    data = cell(size(edges, 1), 2);
    for k = 1:size(edges, 1)
        data{k, 1} = char(names(edges(k, 1)));
        data{k, 2} = char(names(edges(k, 2)));
    end
end

function data = summaryTable(state)
    summary = video_marker.frameAnnotations.summary( ...
        state.project.annotations.frames);
    data = { ...
        'Video', char(video_marker.sourceFiles.pathForId( ...
        state.project.inputs.sources, "video")); ...
        'Frames', sprintf('%d', summary.frameCount); ...
        'Empty', sprintf('%d', summary.empty); ...
        'Draft', sprintf('%d', summary.draft); ...
        'Confirmed', sprintf('%d', summary.confirmed); ...
        'Keypoints', sprintf('%d', numel( ...
        state.project.annotations.skeleton.pointIds))};
end

function value = videoSummary(info)
    if info.frameCount <= 0
        value = "No video loaded";
    else
        value = sprintf('%d frames | %.4g fps | %dx%d px', ...
            info.frameCount, info.frameRate, info.width, info.height);
    end
end

function value = frameStatus(frames, index, currentCount, totalCount, hasVideo)
    if ~hasVideo
        value = "Frame: empty";
        return;
    end
    statusName = video_marker.frameAnnotations.statusName( ...
        frames.frameStatus(index));
    sourceName = video_marker.frameAnnotations.sourceName( ...
        frames.frameSource(index));
    value = sprintf('Frame %d: %s (%s) | points %d / %d', ...
        index, statusName, sourceName, currentCount, totalCount);
end

function value = skeletonStatus(locked, count)
    if locked
        value = sprintf('Skeleton locked for this video (%d keypoints).', count);
    elseif count == 0
        value = "Define keypoints before opening a video.";
    else
        value = sprintf('%d keypoints ready; add connections or open a video.', count);
    end
end

function value = frameTitle(index, hasVideo)
    value = "Frame + Skeleton";
    if hasVideo
        value = "Frame " + string(index);
    end
end

function spec = fileSpec(pathValue, loaded)
    spec = struct("Files", string(pathValue), ...
        "Status", ternary(loaded, "Video loaded", "No video loaded"));
end

function spec = tableSpec(data, enabled)
    spec = struct();
    spec.Data = data;
    spec.Enabled = logical(enabled);
end

function spec = rangeSpec(value, frameCount, enabled)
    upper = max(1, frameCount);
    value = min(max(1, round(double(value))), upper);
    spec = struct("Value", value, "Limits", [1 max(2, upper)], ...
        "Enabled", logical(enabled));
end

function spec = choiceSpec(items, value, enabled)
    spec = struct();
    spec.Items = cellstr(string(items(:)));
    spec.Value = char(string(value));
    spec.Enabled = logical(enabled);
end

function value = validChoice(candidate, choices, fallbackIndex)
    choices = string(choices(:));
    if isempty(choices)
        value = "";
        return;
    end
    value = string(candidate);
    if ~isscalar(value) || ~any(choices == value)
        fallbackIndex = min(max(1, fallbackIndex), numel(choices));
        value = choices(fallbackIndex);
    end
end

function spec = valueSpec(value)
    spec = struct();
    spec.Value = value;
end

function spec = enabledSpec(enabled)
    spec = struct("Enabled", logical(enabled));
end

function spec = controlSpec(enabled, value)
    spec = struct("Enabled", logical(enabled), "Value", value);
end

function value = ternary(condition, trueValue, falseValue)
    if condition
        value = trueValue;
    else
        value = falseValue;
    end
end
