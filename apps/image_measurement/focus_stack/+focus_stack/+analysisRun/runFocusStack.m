% App-owned implementation for focus_stack.analysisRun.runFocusStack within the focus_stack product workflow.
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
paths = context.resolveSourcePaths(state.project.inputs.sources);
task = focus_stack.analysisRun.runTask(paths, images, options, p.autoRegister);
if state.session.cache.result.ok && state.project.results.lastRunFingerprint == task.fingerprint
    context.appendStatus("Focus stack result is already up to date.");
    return;
end
try
    aligned = images;
    lines = strings(0, 1);
    if p.autoRegister
        [aligned, rawLines] = focus_stack.analysisRun.alignImages(images);
        lines = string(rawLines(:));
    end
    result = focus_stack.analysisRun.computeFocusStack(aligned, options);
catch ME
    context.reportError("Focus stacking", ME);
    context.alert(ME.message, "Focus stacking failed");
    context.appendStatus("Focus stacking failed: " + string(ME.message));
    return;
end
state.session.cache.alignedImages = aligned;
state.session.cache.result = result;
state.session.cache.currentFingerprint = task.fingerprint;
state.session.workflow.registrationLines = lines;
state.project.results.lastRun = compact(result);
state.project.results.lastRunFingerprint = task.fingerprint;
state.project.results.registrationLines = lines;
state.project.results.lastExport = [];
state.project.results.resultManifestPath = "";
context.appendStatus(sprintf("Focus stack complete: %d images fused with %s.", result.inputCount, result.method));
for line = lines(:).'
    context.appendStatus(line);
end
end

function value = compact(value)
for name = ["fused" "focusIndex" "confidence"]
    if isfield(value, name)
        value = rmfield(value, name);
    end
end
end
