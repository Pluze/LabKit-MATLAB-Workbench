function state = applyPreset(state, ~, context)
%APPLYPRESET Apply the selected named fusion preset and clear its result.
settings = focus_stack.analysisRun.fusionPresetSettings( ...
    state.project.parameters.fusionPreset);
state.project.parameters.focusWindow = settings.focusWindow;
state.project.parameters.smoothRadius = settings.smoothRadius;
state.project.parameters.uncertainBlend = settings.minConfidencePercent;
state = focus_stack.analysisRun.invalidate(state, [], context);
context.appendStatus("Fusion preset set to " + state.project.parameters.fusionPreset + ".");
end
