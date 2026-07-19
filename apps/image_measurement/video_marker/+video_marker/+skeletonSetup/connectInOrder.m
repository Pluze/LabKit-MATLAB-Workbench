function state=connectInOrder(state,~)
if state.session.cache.videoInfo.frameCount>0,return,end
state.project.annotations.skeleton=video_marker.skeletonDefinition.connectInOrder(state.project.annotations.skeleton);
end
