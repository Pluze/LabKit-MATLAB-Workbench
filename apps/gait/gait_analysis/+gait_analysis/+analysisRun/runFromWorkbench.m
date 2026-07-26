% App-owned implementation for gait_analysis.analysisRun.runFromWorkbench within the gait_analysis product workflow.
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
task = gait_analysis.analysisRun.runTask( ...
    state.session.cache.filepath, pose, options);
if state.project.results.analysis.ok && ...
        state.session.cache.lastRunFingerprint == task.fingerprint
    context.log("info", "gait_analysis.analysisrun.runfromworkbench.status",  ...
        "Gait analysis is already up to date; skipped duplicate run.");
    return
end
try
    result = gait_analysis.analysisRun.computeGait(pose, options);
catch cause
    context.reportError("Gait analysis failed", cause);
    context.alert(cause.message, "Gait analysis failed");
    context.log("info", ...
        "gait_analysis.analysisrun.runfromworkbench.status", ...
        "Gait analysis failed.");
    return
end
state.project.parameters = options;
state.project.results.analysis = result;
state.project.results.lastExport = [];
state.session.cache.lastRunFingerprint = task.fingerprint;
state.session.selection.currentStepIndex = 1;
context.log("info", "gait_analysis.analysisrun.runfromworkbench.status", sprintf("Gait analysis complete: %d valid step(s).", ...
    sum(result.stepTable.is_valid)));
end
