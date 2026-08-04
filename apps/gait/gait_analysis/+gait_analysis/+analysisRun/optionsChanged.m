% App-owned implementation for gait_analysis.analysisRun.optionsChanged within the gait_analysis product workflow.
function applicationState = optionsChanged(applicationState, ~, ~)
%OPTIONSCHANGED Sanitize options and invalidate derived gait results.
applicationState.project.parameters = ...
    gait_analysis.analysisRun.sanitizeOptions( ...
        applicationState.project.parameters);
result = gait_analysis.analysisRun.emptyResult();
result.message = "Analysis options changed; rerun analysis.";
applicationState.project.results.analysis = result;
applicationState.project.results.lastExport = [];
applicationState.session.cache.lastRunFingerprint = "";
applicationState.session.selection.currentStepIndex = 1;
applicationState.session.cache.plotViewRevision = ...
    applicationState.session.cache.plotViewRevision + 1;
end
