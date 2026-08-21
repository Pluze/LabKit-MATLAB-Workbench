%CREATESESSION Rebuild transient Chrono Overlay DTA items and selection.
% Expected caller: LabKit App runtime through chrono_overlay.definition.
% Runtime source records stay lightweight; context resolves their paths.
function session = createSession(project, context)
    arguments
        project (1, 1) struct
        context (1, 1) labkit.app.CallbackContext
    end
    paths = context.resolveSourcePaths(project.inputs.sources);
    items = chrono_overlay.sourceFiles.loadProjectItems(paths);
    session = struct( ...
        "selection", struct("files", labkit.app.event.ListSelection( ...
            Indices=1:numel(paths))), ...
        "cache", struct("items", items));
end
