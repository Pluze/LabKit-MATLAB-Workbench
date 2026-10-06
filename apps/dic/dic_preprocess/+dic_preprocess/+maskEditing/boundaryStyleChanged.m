function applicationState = boundaryStyleChanged( ...
        applicationState, value, ~)
applicationState.project.parameters.maskBoundaryStyle = string(value);
applicationState = dic_preprocess.analysisRun.clearResults(applicationState);
end
