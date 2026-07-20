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
    resource = context.getResource("document", "video");
    if ~isstruct(resource) || ~isscalar(resource) || ...
            ~isfield(resource, "path") || resource.path ~= paths(1)
        resource = video_marker.videoSource.openResource(paths(1));
        context.setResource("document", "video", resource, []);
    end
    info = resource.info;
    [frames, imageData, report] = ...
        video_marker.frameNavigation.loadTargetFrame( ...
        resource.cache.readFrame, state.project.annotations.frames, ...
        startFrame, target, ...
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
        " frame(s) through frame " + string(target) + "; " + ...
        string(report.fallbackPoints) + ...
        " point(s) used motion fallback.");
else
    context.appendStatus("Moved to frame " + string(target) + ".");
end
end
