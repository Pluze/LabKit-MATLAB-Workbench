% App-owned implementation for video_marker.skeletonSetup.addKeypoint within the video_marker product workflow.
function state = addKeypoint(state, context)
%ADDKEYPOINT Append one editable skeleton point.
if state.session.cache.videoInfo.frameCount > 0
    return
end
[state.project.annotations.skeleton, index] = ...
    video_marker.skeletonDefinition.addPoint( ...
        state.project.annotations.skeleton);
state.session.selection.selectedPointIndex = index;
state = video_marker.skeletonSetup.normalizeSelection(state);
state = video_marker.resultFiles.clearExportState(state);
context.log("info", "video_marker.skeletonsetup.addkeypoint.status", ...
    "Added keypoint " + string(index) + ".");
end
