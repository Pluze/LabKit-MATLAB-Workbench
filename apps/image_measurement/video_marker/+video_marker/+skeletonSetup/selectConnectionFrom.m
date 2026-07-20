% App-owned implementation for video_marker.skeletonSetup.selectConnectionFrom within the video_marker product workflow.
function state=selectConnectionFrom(state,value,~)
state.session.selection.connectionFrom=string(value);
end
