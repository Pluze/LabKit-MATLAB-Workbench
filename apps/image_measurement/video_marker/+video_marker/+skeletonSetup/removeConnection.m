function state = removeConnection(state, ~)
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
end
