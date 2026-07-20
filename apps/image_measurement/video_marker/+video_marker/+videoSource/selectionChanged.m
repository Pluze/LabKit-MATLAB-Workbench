% App-owned implementation for video_marker.videoSource.selectionChanged within the video_marker product workflow.
function state = selectionChanged(state, ~, context)
%SELECTIONCHANGED Initialize durable annotations for the selected video.
state.session = video_marker.createSession(state.project, context);
info = state.session.cache.videoInfo;
pointCount = numel(state.project.annotations.skeleton.pointIds);
if info.frameCount > 0 && pointCount == 0
    context.alert("Define at least one keypoint before opening a video.", ...
        "Skeleton required");
    state.project.inputs.sources = struct([]);
    state.session = video_marker.createSession(state.project, context);
    return
end
if info.frameCount <= 0
    context.removeResource("document", "video");
    state.project.inputs.videoMetadata = video_marker.videoSource.emptyMetadata();
    state.project.annotations.frames = ...
        video_marker.frameAnnotations.emptyAnnotations(0, pointCount);
    state.project.parameters.coordinateStartFrame = 1;
    state.project.parameters.coordinateEndFrame = 1;
    state = video_marker.resultFiles.clearExportState(state);
    context.appendStatus("No video loaded.");
    return
end
frames = state.project.annotations.frames;
matches = ~isempty(frames.coords) && ...
    size(frames.coords, 1) == info.frameCount && ...
    size(frames.coords, 2) == pointCount;
if ~matches
    state.project.annotations.frames = ...
        video_marker.frameAnnotations.emptyAnnotations( ...
        info.frameCount, pointCount);
end
state.project.inputs.videoMetadata = ...
    video_marker.videoSource.metadataFromInfo(info);
state.project.parameters.coordinateStartFrame = 1;
state.project.parameters.coordinateEndFrame = info.frameCount;
state = video_marker.resultFiles.clearExportState(state);
context.appendStatus("Opened video with " + string(info.frameCount) + ...
    " frame(s).");
end
