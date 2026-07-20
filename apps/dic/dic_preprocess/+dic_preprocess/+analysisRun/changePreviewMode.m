% App-owned implementation for dic_preprocess.analysisRun.changePreviewMode within the dic_preprocess product workflow.
function state = changePreviewMode(state, value, ~)
state = dic_preprocess.analysisRun.stopEditors(state);
state.project.parameters.previewMode = string(value);
end
