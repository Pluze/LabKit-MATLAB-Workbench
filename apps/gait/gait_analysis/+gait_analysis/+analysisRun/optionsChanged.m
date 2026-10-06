function applicationState = optionsChanged(applicationState, ~, ~)
%OPTIONSCHANGED Sanitize options and invalidate derived gait results.
applicationState.project.parameters = ...
    gait_analysis.analysisRun.sanitizeOptions( ...
        applicationState.project.parameters);
result = gait_analysis.analysisRun.emptyResult();
result.message = "Analysis options changed; rerun analysis.";
applicationState.project.results.analysis = result;

applicationState.session.selection.currentStepIndex = 1;
applicationState.session.cache.plotViewRevision = ...
    applicationState.session.cache.plotViewRevision + 1;
end
