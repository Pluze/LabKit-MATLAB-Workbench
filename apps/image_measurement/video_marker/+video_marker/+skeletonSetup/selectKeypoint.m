% App-owned implementation for video_marker.skeletonSetup.selectKeypoint within the video_marker product workflow.
function state=selectKeypoint(state,selection,~)
if isempty(selection.CellIndices),state.session.selection.selectedPointIndex=0;else,state.session.selection.selectedPointIndex=selection.CellIndices(1,1);end
end
