function commitFilePanel(obj, target, config, sources, indices, rebuildSession)
%COMMITFILEPANEL Rebuild and atomically publish file-panel state.
    if nargin < 6
        rebuildSession = false;
    end
    visibleSources = obj.Sources.recordsForRole( ...
        sources, config.SourceRole);
    if ~(isnumeric(indices) && isrow(indices) && ...
            all(isfinite(indices)) && all(indices == fix(indices)) && ...
            all(indices >= 1) && ...
            all(indices <= numel(visibleSources)))
        error("labkit:app:contract:InvalidValue", ...
            "fileList selection indices are invalid.");
    end
    if strlength(config.SelectionBind) > 0
        ids = strings(1, 0);
        if ~isempty(indices)
            ids = string({visibleSources(indices).id});
        end
        selection = labkit.app.event.ListSelection( ...
            Ids=ids, Indices=indices);
    else
        selection = labkit.app.event.ListSelection(Indices=indices);
    end
    binding = ...
        labkit.app.internal.runtime.RuntimeContractBoundary.signalForTarget( ...
        obj.Contract, target, "listSelectionChanged", false);
    obj.enqueueTransition(binding, selection, @prepareState, ...
        "fileList update for " + string(target), string(target));

    function candidate = prepareState(current)
        candidate = labkit.app.internal.runtime.RuntimeStatePath.write( ...
            current, config.Bind, sources);
        if rebuildSession && ~isempty(obj.Application.RefreshState)
            candidate = obj.Application.RefreshState(candidate, obj.Context);
        end
        if strlength(config.SelectionBind) > 0
            candidate = ...
                labkit.app.internal.runtime.RuntimeStatePath.write( ...
                candidate, config.SelectionBind, selection);
        end
    end
end
