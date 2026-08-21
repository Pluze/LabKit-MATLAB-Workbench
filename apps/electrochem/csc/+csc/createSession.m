% App-owned implementation for csc.createSession within the csc product workflow.
function session = createSession(project, ~)
%CREATESESSION Rebuild transient CSC curves from source-list paths.
paths = labkit.app.source.paths(project.inputs.sources);
items = csc.sourceFiles.loadProjectItems(paths);
fileSelection = labkit.app.event.ListSelection( ...
    Indices=1:min(1, numel(paths)));
choices = csc.analysisRun.analysisChoices();
session = struct("selection", struct( ...
    "files", fileSelection, "currentCurve", choices.allCycles), ...
    "cache", struct("items", items));
end
