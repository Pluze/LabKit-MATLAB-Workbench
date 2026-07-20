% App-owned implementation for video_marker.skeletonSetup.selectConnectionTo within the video_marker product workflow.
function state=selectConnectionTo(state,value,~)
state.session.selection.connectionTo=string(value);
end
