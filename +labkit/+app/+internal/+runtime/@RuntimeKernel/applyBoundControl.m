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
    binding = [];
    if dispatchChanged
        binding = ...
            labkit.app.internal.runtime.RuntimeContractBoundary.signalForTarget( ...
            obj.Contract, target, "valueChanged", false);
    end
    prepareState = @(state) ...
        labkit.app.internal.runtime.RuntimeStatePath.write( ...
        state, path, value);
    obj.enqueueTransition(binding, value, prepareState, ...
        "Bound update for " + string(target), string(target));
end
