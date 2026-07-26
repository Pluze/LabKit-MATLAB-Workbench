% App-owned implementation for video_marker.skeletonSetup.addConnection within the video_marker product workflow.
function state = addConnection(state, context)
%ADDCONNECTION Add the selected editable skeleton edge.
if state.session.cache.videoInfo.frameCount > 0
    return
end
names = string(state.project.annotations.skeleton.pointNames);
a = find(names == state.session.selection.connectionFrom, 1);
b = find(names == state.session.selection.connectionTo, 1);
if isempty(a) || isempty(b) || a == b
    context.alert("Choose two different keypoints.", "Invalid connection");
    return
end
state.project.annotations.skeleton = ...
    video_marker.skeletonDefinition.addEdge( ...
        state.project.annotations.skeleton, a, b);
state.session.selection.selectedEdgeIndex = ...
    size(state.project.annotations.skeleton.edges, 1);
state = video_marker.resultFiles.clearExportState(state);
context.log("info", "video_marker.skeletonsetup.addconnection.status", ...
    "Added a keypoint connection.");
end
