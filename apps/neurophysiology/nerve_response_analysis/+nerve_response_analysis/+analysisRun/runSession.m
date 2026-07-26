% App-owned implementation for nerve_response_analysis.analysisRun.runSession within the nerve_response_analysis product workflow.
function state = runSession(state, context)
if isempty(state.session.cache.filterRecord)
    context.alert("Select a filter record first.", "Nerve response analysis");
    return;
end
options = struct();
if state.project.parameters.maxRecordings > 0
    options.maxRecordings = state.project.parameters.maxRecordings;
end
if state.project.parameters.maxDurationSec > 0
    options.maxDurationSec = state.project.parameters.maxDurationSec;
end
try
    state.session.cache.analysis = nerve_response_analysis.analysisRun.analyzeSession( ...
        state.session.cache.filterRecord, state.session.cache.protocol, options);
catch ME
    context.log("error", "nerve_response_analysis.analysisrun.runsession.exception", "Analyze nerve response", ...
        Category="failure", Audience="developer", Exception=ME);
    state.session.cache.analysis = [];
    state.session.workflow.statusMessage = string(ME.message);
    state.session.workflow.lastAction = "Analysis failed";
    return;
end
state.project.results.lastExport = [];
state.session.workflow.statusMessage = sprintf("Analyzed %d recording(s).", ...
    state.session.cache.analysis.analyzedCount);
state.session.workflow.lastAction = "Analyzed filter record";
context.log("info", "nerve_response_analysis.analysisrun.runsession.completed", ...
    state.session.workflow.statusMessage);
end
