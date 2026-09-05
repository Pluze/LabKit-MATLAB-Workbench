% App-owned implementation for video_marker.frameNavigation.changeFrame within the video_marker product workflow.
function state = changeFrame(state, value, context)
%CHANGEFRAME Read one requested frame without prediction or annotation mutation.
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
    imageData = resource.cache.readFrame(target);
catch cause
    context.log("error", "video_marker.framenavigation.changeframe.exception", "Could not read video frame", ...
        Category="failure", Audience="developer", Exception=cause);
    context.alert(cause.message, "Could not read frame");
    state.session.selection.currentFrame = startFrame;
    return
end
state.session.selection.currentFrame = target;
state.session.cache.currentImage = imageData;
state.session.cache.videoInfo = info;
state.session.cache.videoPath = paths(1);
state.session.cache.frameIndex = target;
state.session.workflow.scaleReferenceEditing = false;
state.session.view.scaleBar = [];
end
