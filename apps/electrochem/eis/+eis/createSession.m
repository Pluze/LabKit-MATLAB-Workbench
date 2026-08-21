% App-owned implementation for eis.createSession within the eis product workflow.
function session = createSession(project, ~)
%CREATESESSION Rebuild EIS overlay curves from source-list paths.
paths = labkit.app.source.paths(project.inputs.sources);
items = eis.sourceFiles.loadProjectItems(paths);
selection = labkit.app.event.ListSelection(Indices=1:numel(paths));
session = struct("selection", struct("files", selection), ...
    "cache", struct("items", items, "plotViewRevision", 0, ...
    "plotViewAction", ""));
end
