function applicationState = optionsChanged(applicationState, ~, ~)
%OPTIONSCHANGED Sanitize options and invalidate derived gait results.
applicationState.project.parameters = ...
    gait_analysis.analysisRun.sanitizeOptions( ...
        applicationState.project.parameters);
hadResult = applicationState.project.results.analysis.ok;
result = gait_analysis.analysisRun.emptyResult();
result.message = "Analysis options changed; rerun analysis.";
applicationState.project.results.analysis = result;

applicationState.session.selection.currentStepIndex = 1;
if hadResult
    applicationState.session.cache.plotViewRevision = ...
        applicationState.session.cache.plotViewRevision + 1;
end
end
