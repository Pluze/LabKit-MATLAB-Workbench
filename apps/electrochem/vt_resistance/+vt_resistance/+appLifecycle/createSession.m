% Expected caller: Runtime V2. Input is one validated VT Resistance project
% with resolved source records. Output owns selection, workflow log, and the
% rebuildable decoded/analyzed DTA cache.
function session = createSession(project)
    items = struct([]);
    currentIndex = 0;
    if ~isempty(project.inputs.sources)
        currentIndex = 1;
        filepath = string(project.inputs.sources(1).reference.originalPath);
        [item, status] = vt_resistance.sourceFiles.loadItem( ...
            filepath, project.parameters);
        if ~status.ok
            error('vt_resistance:SourceLoadFailed', ...
                'Could not load %s: %s', filepath, status.message);
        end
        items = item;
    end
    session = struct( ...
        "selection", struct("currentIndex", currentIndex), ...
        "workflow", struct("logLines", strings(0, 1)), ...
        "view", struct(), ...
        "cache", struct("items", items));
end
