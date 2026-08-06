function enqueueTransition( ...
        obj, binding, payload, prepareState, failureLabel, busyMessage)
%ENQUEUETRANSITION Queue one state preparation and optional App callback.
% Caller: RuntimeKernel input boundaries. PREPARESTATE receives the latest
% committed state when the queued item executes, so reentrant transitions do
% not retain stale candidates. BINDING may be empty for binding-only commits.

    obj.assertOpen();
    if ~isempty(binding)
        labkit.app.internal.runtime.RuntimeContractBoundary.validateDispatch( ...
            obj.Contract, binding, payload);
    end
    if ~isa(prepareState, "function_handle") || ~isscalar(prepareState)
        error("labkit:app:runtime:InvariantFailure", ...
            "Runtime transition preparation must be one function handle.");
    end
    obj.Queue{end + 1} = struct( ...
        "Binding", binding, "Payload", {payload}, ...
        "PrepareState", prepareState, ...
        "FailureLabel", string(failureLabel));
    if obj.Processing
        return;
    end
    obj.Processing = true;
    if isa(obj.Adapter, "labkit.app.internal.native.MatlabPlatformAdapter")
        obj.Adapter.beginBusy(busyMessage);
    end
    cleanup = onCleanup(@() obj.finishProcessing());
    try
        while ~isempty(obj.Queue)
            item = obj.Queue{1};
            obj.Queue(1) = [];
            obj.execute(item.Binding, item.Payload, ...
                item.PrepareState, item.FailureLabel);
        end
    catch cause
        obj.Queue = {};
        rethrow(cause);
    end
    clear cleanup
end
