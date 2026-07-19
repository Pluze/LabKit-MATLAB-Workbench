function state=removeKeypoint(state,~)
index=state.session.selection.selectedPointIndex;if state.session.cache.videoInfo.frameCount>0||index<1,return,end
state.project.annotations.skeleton=video_marker.skeletonDefinition.removePoint(state.project.annotations.skeleton,index);
state.session.selection.selectedPointIndex=0;
state.session.selection.selectedEdgeIndex=0;
state=video_marker.skeletonSetup.normalizeSelection(state);
end
