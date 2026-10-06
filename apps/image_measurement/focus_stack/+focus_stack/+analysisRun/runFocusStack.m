function state = runFocusStack(state, context)
%RUNFOCUSSTACK Compute one deterministic fusion from the rebuilt source cache.
images = state.session.cache.images;
if numel(images) < 2
    context.alert("Load at least two images before running focus stacking.", "Not enough images");
    return;
end
p = state.project.parameters;
options = struct("focusWindow", p.focusWindow, "smoothRadius", p.smoothRadius, ...
    "minConfidence", p.uncertainBlend / 100);
try
    aligned = images;
    lines = strings(0, 1);
    if p.autoRegister
        [aligned, rawLines] = focus_stack.analysisRun.alignImages(images);
        lines = string(rawLines(:));
    end
    result = focus_stack.analysisRun.computeFocusStack(aligned, options);
catch ME
    context.log("error", "focus_stack.analysisrun.runfocusstack.exception", "Focus stacking", ...
        Category="failure", Audience="developer", Exception=ME);
    context.alert(ME.message, "Focus stacking failed");
    context.log("error", "focus_stack.analysisrun.runfocusstack.failed", ...
        "Focus stacking failed.");
    return;
end
state.session.cache.result = result;
state.session.cache.plotViewRevision = ...
    state.session.cache.plotViewRevision + 1;
state.project.results.registrationLines = lines;

state.project.results.lastOutputPath = "";
context.log("info", "focus_stack.analysisrun.runfocusstack.completed", ...
    sprintf("Focus stack complete: %d images fused.", result.inputCount));
if ~isempty(lines)
    context.log("debug", ...
        "focus_stack.analysisrun.runfocusstack.registration_details", ...
        sprintf("Recorded %d registration detail(s).", numel(lines)), ...
        Audience="developer");
end
end
