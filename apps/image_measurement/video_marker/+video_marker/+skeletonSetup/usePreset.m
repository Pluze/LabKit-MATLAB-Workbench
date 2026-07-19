function state = usePreset(state, ~)
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
end
