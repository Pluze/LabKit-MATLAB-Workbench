function state = changePreviewMode(state, value, ~)
state = dic_preprocess.analysisRun.stopEditors(state);
state.project.parameters.previewMode = string(value);
end
