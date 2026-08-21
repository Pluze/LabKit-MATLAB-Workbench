% App-owned implementation for csc.createSession within the csc product workflow.
function session = createSession(project, context)
%CREATESESSION Rebuild transient CSC curves from source-list paths.
arguments
    project (1, 1) struct
    context (1, 1) labkit.app.CallbackContext
end
paths = context.resolveSourcePaths(project.inputs.sources);
items = csc.sourceFiles.loadProjectItems(paths);
fileSelection = labkit.app.event.ListSelection( ...
    Indices=1:min(1, numel(paths)));
choices = csc.analysisRun.analysisChoices();
session = struct("selection", struct( ...
    "files", fileSelection, "currentCurve", choices.allCycles), ...
    "cache", struct("items", items));
end
