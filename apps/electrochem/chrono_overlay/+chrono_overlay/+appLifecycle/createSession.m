% Expected caller: the LabKit V2 runtime. Input is a validated Chrono Overlay
% project. Output owns ephemeral selection, workflow log, view, and cache data.
function session = createSession(project)
    items = chrono_overlay.sourceFiles.loadProjectItems(project.inputs.sources);
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
