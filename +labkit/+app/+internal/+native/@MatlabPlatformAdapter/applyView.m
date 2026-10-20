function applyView(obj, view, previous)
% Class-folder implementation of MatlabPlatformAdapter.applyView.
    if nargin < 3
        previous = [];
    end
    obj.BusyLifecycle.setWindowSubtitle(view.windowSubtitleForNative());
    operations = labkit.app.internal.native.NativeAdapterValues.orderedOperations(view.operationsForCompiler());
    interactionOperations = operations(cellfun(@(operation) ...
        labkit.app.internal.native.NativeAdapterValues.isInteractionKind(operation.Kind), operations));
    operations = operations(~cellfun(@(operation) ...
        labkit.app.internal.native.NativeAdapterValues.isInteractionKind(operation.Kind), operations));
    previousOperations = cell(1, 0);
    previousInteractions = cell(1, 0);
    if isa(previous, "labkit.app.view.Snapshot")
        prior = labkit.app.internal.native.NativeAdapterValues.orderedOperations( ...
            previous.operationsForCompiler());
        previousInteractions = prior(cellfun(@(operation) ...
            labkit.app.internal.native.NativeAdapterValues.isInteractionKind(operation.Kind), prior));
        previousOperations = prior(~cellfun(@(operation) ...
            labkit.app.internal.native.NativeAdapterValues.isInteractionKind(operation.Kind), prior));
    end
    changed = changedOperations(operations, previousOperations);
    for k = 1:numel(changed)
        operation = changed{k};
        try
            obj.apply(operation);
        catch cause
            failure = MException( ...
                "labkit:app:native:OperationFailed", ...
                "Could not apply native %s operation to semantic target %s.", ...
                operation.Kind, operation.Target);
            failure = addCause(failure, cause);
            throw(failure)
        end
    end
    if ~isempty(obj.InteractionController) && ...
            ~isempty(changedOperations(interactionOperations, previousInteractions))
        obj.InteractionController.reconcile( ...
            obj.Plan.Interactions, interactionOperations);
    end
end

function changed = changedOperations(current, previous)
if isempty(current) || isempty(previous)
    changed = current;
    return
end
currentKeys = string(cellfun(@operationKey, current, UniformOutput=false));
previousKeys = string(cellfun(@operationKey, previous, UniformOutput=false));
[found, indices] = ismember(currentKeys, previousKeys);
changed = cell(1, numel(current));
changedCount = 0;
for index = 1:numel(current)
    operation = current{index};
    if ~found(index) || ~isequaln(previous{indices(index)}.Value, operation.Value)
        changedCount = changedCount + 1;
        changed{changedCount} = operation;
    end
end
changed = changed(1:changedCount);
end

function key = operationKey(operation)
key = operation.Kind + ":" + operation.Target;
end
