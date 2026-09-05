function applicationState = predictToFrame(applicationState, callbackContext)
%PREDICTTOFRAME Explicitly propagate an immutable annotation snapshot through a range.
project = applicationState.project;
session = applicationState.session;
start = session.cache.frameIndex;
target = min(session.cache.videoInfo.frameCount, round(session.selection.predictionEndFrame));
if target <= start
    callbackContext.alert("Choose a prediction end frame after the current frame.", "No forward range");
    return
end
paths = labkit.app.source.paths(project.inputs.sources);
if isempty(paths) || ~isfile(paths(1))
    callbackContext.alert("The source video is unavailable.", "Cannot predict");
    return
end
try
    resource = callbackContext.getResource("video");
    if ~isstruct(resource) || ~isfield(resource, "path") || resource.path ~= paths(1)
        resource = video_marker.videoSource.openResource(paths(1));
        callbackContext.setResource("video", resource, []);
    end
    [frames, imageData, report] = video_marker.motionEstimate.predictForward( ...
        resource.cache.readFrame, project.annotations.frames, start, target, session.cache.currentImage, ...
        @(stage, index, count) reportProgress(callbackContext, stage, index, count));
catch cause
    callbackContext.log("error", "video_marker.prediction.failed", ...
        "Could not predict the requested frame range.", Category="failure", ...
        Audience="developer", Exception=cause);
    callbackContext.alert(cause.message, "Prediction failed");
    return
end
applicationState.project.annotations.frames = frames;
applicationState.project.results.markerOutputPath = "";
applicationState.project.results.coordinateOutputPath = "";
applicationState.session.selection.currentFrame = target;
applicationState.session.cache.frameIndex = target;
applicationState.session.cache.currentImage = imageData;
applicationState.session.cache.videoInfo = resource.info;
applicationState.session.workflow.scaleReferenceEditing = false;
applicationState.session.view.scaleBar = [];
callbackContext.log("info", "video_marker.prediction.completed", ...
    "Completed the requested prediction range; predicted frames remain drafts.", ...
    Attributes=struct("count", report.predictedFrames));
end

function reportProgress(context, stage, index, count)
context.log("info", "video_marker.prediction.progress", ...
    sprintf("Range prediction %s: frame %d of %d.", stage, index, count), ...
    Category="progress", Audience="developer", ...
    Attributes=struct("enum", stage, "completedCount", index, "totalCount", count));
end
