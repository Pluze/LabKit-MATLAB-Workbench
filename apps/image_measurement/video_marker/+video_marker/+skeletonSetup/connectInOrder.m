function state = connectInOrder(state, context)
%CONNECTINORDER Add every adjacent ordered keypoint edge.
if state.session.cache.videoInfo.frameCount > 0 || ...
        numel(state.project.annotations.skeleton.pointNames) < 2
    return
end
state.project.annotations.skeleton = ...
    video_marker.skeletonDefinition.connectInOrder( ...
        state.project.annotations.skeleton);
state.session.selection.selectedEdgeIndex = 0;
state = video_marker.resultFiles.clearExportState(state);
context.appendStatus("Connected adjacent keypoints in order.");
end
