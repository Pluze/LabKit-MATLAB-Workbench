function state=renameKeypoint(state,edit,context)
if state.session.cache.videoInfo.frameCount>0,return,end
if edit.ColumnIndex~=2,return,end
try
    state.project.annotations.skeleton=video_marker.skeletonDefinition.renamePoint( ...
        state.project.annotations.skeleton,edit.RowIndex,edit.NewValue);
    state=video_marker.skeletonSetup.normalizeSelection(state);
catch ME
    context.reportError("Invalid keypoint name",ME);
    context.alert(ME.message,"Invalid keypoint");
end
end
