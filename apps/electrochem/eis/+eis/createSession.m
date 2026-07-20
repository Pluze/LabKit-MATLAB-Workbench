% App-owned implementation for eis.createSession within the eis product workflow.
function session = createSession(project, context)
%CREATESESSION Rebuild EIS overlay curves from portable source references.
arguments
    project (1, 1) struct
    context (1, 1) labkit.app.CallbackContext
end
paths = context.resolveSourcePaths(project.inputs.sources);
items = eis.sourceFiles.loadProjectItems(paths);
selection = labkit.app.event.ListSelection(Indices=1:numel(paths));
session = struct("selection", struct("files", selection), ...
    "cache", struct("items", items));
end
