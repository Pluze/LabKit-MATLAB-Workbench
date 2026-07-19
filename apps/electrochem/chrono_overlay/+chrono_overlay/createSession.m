%CREATESESSION Rebuild transient Chrono Overlay DTA items and selection.
% Expected caller: LabKit UI runtime through chrono_overlay.definition.
% Portable sources remain opaque; context resolves their current paths.
function session = createSession(project, context)
    paths = context.sourcePaths(project.inputs.sources);
    items = chrono_overlay.sourceFiles.loadProjectItems(paths);
    session = struct( ...
        "selection", struct("files", labkit.ui.Selection( ...
            Indices=1:numel(paths))), ...
        "cache", struct("items", items));
end
