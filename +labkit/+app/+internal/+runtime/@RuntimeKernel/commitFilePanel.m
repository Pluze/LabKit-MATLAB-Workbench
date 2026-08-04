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
    candidate = labkit.app.internal.runtime.RuntimeStatePath.write( ...
        obj.State, config.Bind, sources);
    if rebuildSession && ~isempty(obj.Application.CreateSession)
        candidate.session = obj.Application.CreateSession( ...
            candidate.project, obj.Context);
    end
    if strlength(config.SelectionBind) > 0
        ids = strings(1, 0);
        if ~isempty(indices)
            ids = string({visibleSources(indices).id});
        end
        selection = labkit.app.event.ListSelection( ...
            Ids=ids, Indices=indices);
        candidate = labkit.app.internal.runtime.RuntimeStatePath.write( ...
            candidate, config.SelectionBind, selection);
    else
        selection = labkit.app.event.ListSelection(Indices=indices);
    end
    binding = ...
        labkit.app.internal.runtime.RuntimeContractBoundary.signalForTarget( ...
        obj.Contract, target, "listSelectionChanged", false);
    if ~isempty(binding)
        candidate = binding.UpdateState( ...
            candidate, selection, obj.Context);
    end
    previousState = obj.State;
    previousPresentation = obj.Presentation;
    try
        labkit.app.internal.runtime.RuntimeContractBoundary.validateState( ...
            obj.Application, candidate);
        view = obj.present(candidate);
        obj.Adapter.reconcile(previousPresentation, view);
        obj.State = candidate;
        obj.Presentation = view;
        obj.markDocumentChanged();
    catch cause
        obj.State = previousState;
        obj.Presentation = previousPresentation;
        failure = MException("labkit:app:runtime:ActionFailed", ...
            "fileList update for %s failed transactionally.", target);
        failure = addCause(failure, cause);
        throwAsCaller(failure);
    end
end
