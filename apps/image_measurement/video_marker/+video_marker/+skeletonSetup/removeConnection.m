% App-owned implementation for video_marker.skeletonSetup.removeConnection within the video_marker product workflow.
function state = removeConnection(state, context)
%REMOVECONNECTION Remove the selected editable skeleton edge.
index = state.session.selection.selectedEdgeIndex;
count = size(state.project.annotations.skeleton.edges, 1);
if state.session.cache.videoInfo.frameCount > 0 || index < 1 || index > count
    return
end
state.project.annotations.skeleton = ...
    video_marker.skeletonDefinition.removeEdge( ...
    state.project.annotations.skeleton, index);
state.session.selection.selectedEdgeIndex = min(index, ...
    size(state.project.annotations.skeleton.edges, 1));
state = video_marker.resultFiles.clearExportState(state);
context.appendStatus("Removed connection " + string(index) + ".");
end
