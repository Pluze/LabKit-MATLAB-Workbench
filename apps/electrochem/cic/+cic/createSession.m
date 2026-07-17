%CREATESESSION Rebuild the selected CIC preview item lazily.
% Expected caller: Runtime V2 through cic.definition. Only the first source is
% decoded for immediate preview; the full batch remains deferred to export.
function session = createSession(project)
    items = struct([]);
    currentIndex = 0;
    if ~isempty(project.inputs.sources)
        currentIndex = 1;
        filepath = string(project.inputs.sources(1).reference.originalPath);
        [item, status] = cic.sourceFiles.loadItem(filepath, project.parameters);
        if ~status.ok
            error('cic:SourceLoadFailed', 'Could not load %s: %s', ...
                filepath, status.message);
        end
        items = item;
    end
    session = struct( ...
        "selection", struct("currentIndex", currentIndex), ...
        "workflow", struct("logLines", strings(0, 1)), ...
        "view", struct(), ...
        "cache", struct("items", items));
end
