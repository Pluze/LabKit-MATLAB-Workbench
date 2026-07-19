function state = changeFrame(state, value, context)
%CHANGEFRAME Decode the requested frame from the portable video source.
info = state.session.cache.videoInfo;
if info.frameCount <= 0 || isempty(state.session.cache.currentImage)
    return
end
target = min(max(1, round(double(value))), info.frameCount);
startFrame = state.session.cache.frameIndex;
if target == startFrame
    state.session.selection.currentFrame = target;
    return
end
paths = context.resolveSourcePaths(state.project.inputs.sources);
if isempty(paths) || ~isfile(paths(1))
    state.session.selection.currentFrame = startFrame;
    return
end
try
    [reader, info] = video_marker.videoSource.openVideo(paths(1));
    readFrame = @(index) video_marker.videoSource.readFrame(reader, index);
    [frames, imageData, report] = ...
        video_marker.frameNavigation.loadTargetFrame( ...
        readFrame, state.project.annotations.frames, startFrame, target, ...
        state.session.cache.currentImage, ...
        numel(state.project.annotations.skeleton.pointIds));
catch cause
    context.reportError("Could not read video frame", cause);
    context.alert(cause.message, "Could not read frame");
    state.session.selection.currentFrame = startFrame;
    return
end
if frames.frameStatus(target) == ...
        video_marker.frameAnnotations.statusCode("empty")
    frames = video_marker.frameAnnotations.inheritDraft(frames, target);
end
state.project.annotations.frames = frames;
state.session.selection.currentFrame = target;
state.session.cache.currentImage = imageData;
state.session.cache.videoInfo = info;
state.session.cache.videoPath = paths(1);
state.session.cache.frameIndex = target;
state.session.workflow.scaleReferenceEditing = false;
state.session.view.scaleBar = [];
state = video_marker.resultFiles.clearExportState(state);
if report.predictedFrames > 0
    context.appendStatus("Predicted " + string(report.predictedFrames) + ...
        " frame(s) through frame " + string(target) + ".");
else
    context.appendStatus("Moved to frame " + string(target) + ".");
end
end
