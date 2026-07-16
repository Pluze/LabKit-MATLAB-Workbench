% Expected caller: Runtime V2. Input is a validated EIS project. Output owns
% selected sources, workflow log, and rebuildable decoded EIS item cache.
function session = createSession(project)
    items = eis.sourceFiles.loadProjectItems(project.inputs.sources);
    selectedPaths = strings(0, 1);
    if ~isempty(items)
        selectedPaths = string({items.filepath}).';
    end
    session = struct( ...
        "selection", struct("paths", selectedPaths), ...
        "workflow", struct("logLines", strings(0, 1)), ...
        "view", struct(), ...
        "cache", struct("items", items));
end
