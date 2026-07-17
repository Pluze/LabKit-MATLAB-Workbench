%CREATESESSION Rebuild the selected VT Resistance preview item lazily.
% Expected caller: Runtime V2 through vt_resistance.definition. Only the first
% source is decoded immediately; full-batch analysis remains export-time work.
function session = createSession(project)
    items = struct([]);
    currentIndex = 0;
    if ~isempty(project.inputs.sources)
        currentIndex = 1;
        filepath = labkit.ui.runtime.sourcePaths( ...
            project.inputs.sources(1));
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
