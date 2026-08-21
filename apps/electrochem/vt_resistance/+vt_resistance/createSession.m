% App-owned implementation for vt_resistance.createSession within the vt_resistance product workflow.
function session = createSession(project, ~)
%CREATESESSION Rebuild VT Resistance's lazy selected preview.
paths = strings(0, 1);
if ~isempty(project.inputs.sources)
    paths = labkit.app.source.paths(project.inputs.sources);
end
items = vt_resistance.sourceFiles.loadProjectItems( ...
    paths, project.parameters);
selection = labkit.app.event.ListSelection( ...
    Indices=1:min(1, numel(items)));
session = struct("selection", struct("files", selection), ...
    "cache", struct("items", items));
end
