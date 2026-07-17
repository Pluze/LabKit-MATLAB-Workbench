%CREATESESSION Rebuild transient Chrono Overlay DTA items and selection.
% Expected caller: Runtime V2 through chrono_overlay.definition. Input is a
% validated current project; decoded DTA curves remain outside persistence.
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
