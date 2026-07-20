% App-owned implementation for dic_preprocess.maskEditing.boundaryStyleChanged within the dic_preprocess product workflow.
function applicationState = boundaryStyleChanged( ...
        applicationState, value, ~)
applicationState.project.parameters.maskBoundaryStyle = string(value);
applicationState = dic_preprocess.analysisRun.clearResults(applicationState);
end
