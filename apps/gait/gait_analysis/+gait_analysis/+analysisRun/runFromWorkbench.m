function state = runFromWorkbench(state, context)
%RUNFROMWORKBENCH Compute gait results from the rebuilt pose session.
arguments
    state (1, 1) struct
    context (1, 1) labkit.app.CallbackContext
end
pose = state.session.cache.pose;
if ~pose.ok
    context.alert("Open a current Video Marker MAT before running gait analysis.", "No pose data");
    return
end
options = gait_analysis.analysisRun.sanitizeOptions( ...
    state.project.parameters);
try
    result = gait_analysis.analysisRun.computeGait(pose, options);
catch cause
    context.log("error", "gait_analysis.analysisrun.runfromworkbench.exception", "Gait analysis failed", ...
        Category="failure", Audience="developer", Exception=cause);
    context.alert(cause.message, "Gait analysis failed");
    context.log("info", ...
        "gait_analysis.analysisrun.runfromworkbench.status", ...
        "Gait analysis failed.");
    return
end
state.project.parameters = options;
state.project.results.analysis = result;

state.session.selection.currentStepIndex = 1;
state.session.cache.plotViewRevision = ...
    state.session.cache.plotViewRevision + 1;
context.log("info", "gait_analysis.analysisrun.runfromworkbench.status", sprintf("Gait analysis complete: %d valid step(s).", ...
    sum(result.stepTable.is_valid)));
end
