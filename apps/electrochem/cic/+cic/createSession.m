% App-owned implementation for cic.createSession within the cic product workflow.
function session = createSession(project, ~)
%CREATESESSION Rebuild CIC's lazy selected preview from source-list paths.
paths = labkit.app.source.paths(project.inputs.sources);
items = cic.sourceFiles.loadProjectItems(paths, project.parameters);
selection = labkit.app.event.ListSelection(Indices=1:min(1, numel(items)));
session = struct("selection", struct("files", selection), ...
    "cache", struct("items", items));
end
