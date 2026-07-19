function state=addConnection(state,context)
if state.session.cache.videoInfo.frameCount>0,return,end
names=string(state.project.annotations.skeleton.pointNames);a=find(names==state.session.selection.connectionFrom,1);b=find(names==state.session.selection.connectionTo,1);
if isempty(a)||isempty(b)||a==b,context.alert("Choose two different keypoints.","Invalid connection");return,end
state.project.annotations.skeleton=video_marker.skeletonDefinition.addEdge(state.project.annotations.skeleton,a,b);
end
