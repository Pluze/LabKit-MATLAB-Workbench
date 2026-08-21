% App-owned implementation for video_marker.frameNavigation.changeFrame within the video_marker product workflow.
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
paths = labkit.app.source.paths(state.project.inputs.sources);
if isempty(paths) || ~isfile(paths(1))
    state.session.selection.currentFrame = startFrame;
    return
end
try
    resource = context.getResource("video");
    if ~isstruct(resource) || ~isscalar(resource) || ...
            ~isfield(resource, "path") || resource.path ~= paths(1)
        resource = video_marker.videoSource.openResource(paths(1));
        context.setResource("video", resource, []);
    end
    info = resource.info;
    [frames, imageData, report] = ...
        video_marker.frameNavigation.loadTargetFrame( ...
        resource.cache.readFrame, state.project.annotations.frames, ...
        startFrame, target, ...
        state.session.cache.currentImage, ...
        numel(state.project.annotations.skeleton.pointIds));
catch cause
    context.log("error", "video_marker.framenavigation.changeframe.exception", "Could not read video frame", ...
        Category="failure", Audience="developer", Exception=cause);
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
    context.log("info", "video_marker.framenavigation.changeframe.predicted", ...
        "Predicted " + string(report.predictedFrames) + ...
        " frame(s) through frame " + string(target) + "; " + ...
        string(report.fallbackPoints) + ...
        " point(s) used motion fallback.");
else
    context.log("info", "video_marker.framenavigation.changeframe.moved", ...
        "Moved to frame " + string(target) + ".");
end
end
