% App-owned implementation for video_marker.skeletonSetup.renameKeypoint within the video_marker product workflow.
function state=renameKeypoint(state,edit,context)
if state.session.cache.videoInfo.frameCount>0,return,end
if edit.ColumnIndex~=2,return,end
try
    state.project.annotations.skeleton=video_marker.skeletonDefinition.renamePoint( ...
        state.project.annotations.skeleton,edit.RowIndex,edit.NewValue);
    state=video_marker.skeletonSetup.normalizeSelection(state);
    state=video_marker.resultFiles.clearExportState(state);
    context.appendStatus("Renamed keypoint " + string(edit.RowIndex) + ".");
catch ME
    context.reportError("Invalid keypoint name", ME);
    context.alert(ME.message, "Invalid keypoint name");
end
end
