% App-owned implementation for vt_resistance.createSession within the vt_resistance product workflow.
function session = createSession(project, context)
%CREATESESSION Rebuild VT Resistance's lazy selected preview.
arguments
    project (1, 1) struct
    context (1, 1) labkit.app.CallbackContext
end
paths = strings(0, 1);
if ~isempty(project.inputs.sources)
    paths = context.resolveSourcePaths(project.inputs.sources);
end
items = vt_resistance.sourceFiles.loadProjectItems( ...
    paths, project.parameters);
selection = labkit.app.event.ListSelection( ...
    Indices=1:min(1, numel(items)));
session = struct("selection", struct("files", selection), ...
    "cache", struct("items", items));
end
