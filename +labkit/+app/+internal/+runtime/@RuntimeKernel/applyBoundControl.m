function applyBoundControl(obj, target, value, dispatchChanged)
%APPLYBOUNDCONTROL Commit one declared bound-control state transition.
    obj.assertOpen();
    if nargin < 4
        dispatchChanged = false;
    end
    plan = obj.Contract.PlatformPlan;
    index = find(string({plan.Nodes.Id}) == string(target), 1);
    if isempty(index) || ~isfield(plan.Nodes(index).Configuration, "Bind")
        error("labkit:app:contract:UnknownReference", ...
            "Layout target has no state binding: %s.", target);
    end
    path = plan.Nodes(index).Configuration.Bind;
    if strlength(path) == 0
        error("labkit:app:contract:UnknownReference", ...
            "Layout target has no state binding: %s.", target);
    end
    previousState = obj.State;
    previousPresentation = obj.Presentation;
    try
        candidate = labkit.app.internal.runtime.RuntimeStatePath.write( ...
            previousState, path, value);
        if dispatchChanged
            binding = ...
                labkit.app.internal.runtime.RuntimeContractBoundary.signalForTarget( ...
                obj.Contract, target, "valueChanged", false);
            if ~isempty(binding)
                candidate = binding.UpdateState( ...
                    candidate, value, obj.Context);
            end
        end
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
            "Bound update for %s failed transactionally.", target);
        failure = addCause(failure, cause);
        throwAsCaller(failure);
    end
end
