% App-owned implementation for video_marker.scaleCalibration.toggleReference within the video_marker product workflow.
function state = toggleReference(state, context)
%TOGGLEREFERENCE Enable or finish managed reference-line editing.
if state.session.cache.videoInfo.frameCount <= 0
    context.alert("Open a video before measuring reference pixels.", ...
        "No video loaded");
    return
end
state.session.workflow.scaleReferenceEditing = ...
    ~state.session.workflow.scaleReferenceEditing;
state.session.view.scaleBar = [];
end
