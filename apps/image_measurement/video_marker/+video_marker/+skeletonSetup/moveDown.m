function state=moveDown(state,~)
if state.session.cache.videoInfo.frameCount>0,return,end
[state.project.annotations.skeleton,state.session.selection.selectedPointIndex]=video_marker.skeletonDefinition.movePoint(state.project.annotations.skeleton,state.session.selection.selectedPointIndex,1);
end
