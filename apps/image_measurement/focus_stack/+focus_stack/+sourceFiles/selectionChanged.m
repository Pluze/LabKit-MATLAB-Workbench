% App-owned implementation for focus_stack.sourceFiles.selectionChanged within the focus_stack product workflow.
function applicationState = selectionChanged( ...
        applicationState, listSelection, callbackContext)
%SELECTIONCHANGED Reconcile source-derived result and output state.
% Called after the framework updates the portable source list or its visible
% selection. Source replacement rebuilds the decoded session before this
% callback; a selection-only change leaves a current result intact.
paths = applicationState.session.cache.sourcePaths;
if isempty(paths)
    if ~isempty(applicationState.project.inputs.sources)
        paths = callbackContext.resolveSourcePaths( ...
            applicationState.project.inputs.sources);
    end
else
    paths = string(paths(:));
end
if strlength(applicationState.project.parameters.outputFolder) == 0 && ...
        ~isempty(paths)
    applicationState.project.parameters.outputFolder = ...
        string(fileparts(paths(1)));
end
if isempty(applicationState.project.results.lastRunFingerprint)
    return;
end
parameters = applicationState.project.parameters;
options = struct( ...
    "focusWindow", parameters.focusWindow, ...
    "smoothRadius", parameters.smoothRadius, ...
    "minConfidence", parameters.uncertainBlend / 100);
task = focus_stack.analysisRun.runTask(paths, ...
    applicationState.session.cache.images, options, ...
    parameters.autoRegister);
if task.fingerprint ~= ...
        applicationState.project.results.lastRunFingerprint
    applicationState = focus_stack.analysisRun.invalidate( ...
        applicationState, listSelection, callbackContext);
end
end
