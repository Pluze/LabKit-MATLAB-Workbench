%CREATESESSION Rebuild transient EIS curves and selected source paths.
% Expected caller: Runtime V2 through eis.definition. Decoded ZCURVE data and
% selection remain outside the durable project.
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
