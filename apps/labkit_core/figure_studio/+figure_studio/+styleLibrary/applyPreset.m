function state = applyPreset(state, preset, ~)
preset = string(preset); state.project.parameters.preset = preset; state.project.parameters.style = figure_studio.styleLibrary.styleForPreset(preset);
end
