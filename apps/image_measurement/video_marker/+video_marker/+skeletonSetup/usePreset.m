% App-owned implementation for video_marker.skeletonSetup.usePreset within the video_marker product workflow.
function state = usePreset(state, context)
%USEPRESET Replace the editable skeleton with the selected preset.
if state.session.cache.videoInfo.frameCount > 0
    return
end
presets = video_marker.skeletonSetup.presets();
match = find([presets.label] == string( ...
    state.session.selection.skeletonPreset), 1);
if isempty(match)
    return
end
state.project.annotations.skeleton = ...
    video_marker.skeletonDefinition.fromParts( ...
    presets(match).pointNames, presets(match).edges);
state = video_marker.skeletonSetup.normalizeSelection(state, true);
state = video_marker.resultFiles.clearExportState(state);
context.appendStatus("Applied skeleton preset: " + ...
    string(presets(match).label) + ".");
end
