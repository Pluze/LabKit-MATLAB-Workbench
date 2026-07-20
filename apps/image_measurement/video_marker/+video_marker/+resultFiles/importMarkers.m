function state = importMarkers(state, context)
%IMPORTMARKERS Replace annotations from a validated round-trip marker CSV.
choice = context.chooseInputFile( ...
    ["*.csv", "Marker CSV files"], pwd);
if choice.Cancelled
    context.appendStatus("Marker import cancelled.");
    return
end
filepath = string(choice.Value);
try
    payload = video_marker.markerCsv.readFile(filepath);
catch cause
    context.reportError("Could not import marker CSV", cause);
    context.alert(cause.message, "Could not import marker CSV");
    return
end
state.project.annotations.skeleton = payload.skeleton;
state.project.annotations.frames = payload.annotations;
state.project.annotations.calibration = payload.calibration;
state.project.inputs.videoMetadata = ...
    video_marker.videoSource.metadataFromInfo(payload.videoInfo);
videoPath = string(payload.videoInfo.path);
if strlength(videoPath) > 0
    state.project.inputs.sources = labkit.app.project.sourceRecord( ...
        "video", "video", videoPath, isfile(videoPath));
else
    state.project.inputs.sources = struct([]);
end
state = video_marker.skeletonSetup.normalizeSelection(state, true);
state.session = video_marker.createSession(state.project, context);
if ~isempty(state.session.cache.currentImage)
    info = state.session.cache.videoInfo;
    if size(payload.annotations.coords, 1) ~= info.frameCount || ...
            size(payload.annotations.coords, 2) ~= ...
            numel(payload.skeleton.pointIds)
        context.alert( ...
            "Imported annotations do not match the referenced video.", ...
            "Marker CSV mismatch");
        state.session.cache.currentImage = [];
    end
end
state.project.parameters.coordinateStartFrame = 1;
state.project.parameters.coordinateEndFrame = ...
    max(1, payload.videoInfo.frameCount);
state = video_marker.resultFiles.clearExportState(state);
context.appendStatus("Imported marker CSV: " + filepath);
end
