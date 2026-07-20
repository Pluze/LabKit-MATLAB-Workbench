% App-owned implementation for video_marker.skeletonSetup.removeKeypoint within the video_marker product workflow.
function state = removeKeypoint(state, context)
%REMOVEKEYPOINT Remove the selected editable skeleton point.
index = state.session.selection.selectedPointIndex;
names = state.project.annotations.skeleton.pointNames;
if state.session.cache.videoInfo.frameCount > 0 || ...
        index < 1 || index > numel(names)
    return
end
state.project.annotations.skeleton = ...
    video_marker.skeletonDefinition.removePoint( ...
        state.project.annotations.skeleton, index);
state.session.selection.selectedPointIndex = min( ...
    index, numel(state.project.annotations.skeleton.pointNames));
state.session.selection.selectedEdgeIndex = 0;
state = video_marker.skeletonSetup.normalizeSelection(state);
state = video_marker.resultFiles.clearExportState(state);
context.appendStatus("Removed keypoint " + string(index) + ".");
end
