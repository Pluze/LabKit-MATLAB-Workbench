function state=addKeypoint(state,~)
if state.session.cache.videoInfo.frameCount>0,return,end
[state.project.annotations.skeleton,index]=video_marker.skeletonDefinition.addPoint(state.project.annotations.skeleton);
state.session.selection.selectedPointIndex=index;
state=video_marker.skeletonSetup.normalizeSelection(state);
end
