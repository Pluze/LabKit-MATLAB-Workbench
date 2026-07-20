function applyView(obj, view)
% Class-folder implementation of MatlabPlatformAdapter.applyView.
    operations = labkit.app.internal.NativeAdapterValues.orderedOperations(view.operationsForCompiler());
    interactionOperations = operations(cellfun(@(operation) ...
        labkit.app.internal.NativeAdapterValues.isInteractionKind(operation.Kind), operations));
    operations = operations(~cellfun(@(operation) ...
        labkit.app.internal.NativeAdapterValues.isInteractionKind(operation.Kind), operations));
    for k = 1:numel(operations)
        obj.apply(operations{k});
    end
    if ~isempty(obj.InteractionController)
        obj.InteractionController.reconcile( ...
            obj.InteractionDeclarations, interactionOperations);
    end
end
