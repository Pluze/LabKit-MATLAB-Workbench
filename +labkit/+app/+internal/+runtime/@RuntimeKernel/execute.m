function execute(obj, binding, payload, prepareState, failureLabel)
%EXECUTE Run one prepared callback transaction with presentation rollback.
    if nargin < 4
        prepareState = @(state) state;
    end
    if nargin < 5
        failureLabel = "Callback " + binding.Id;
    end
    previousState = obj.State;
    previousPresentation = obj.Presentation;
    hasCallback = ~isempty(binding);
    try
        candidate = prepareState(previousState);
        if hasCallback
            if ~binding.AcceptsPayload
                candidate = binding.UpdateState(candidate, obj.Context);
            else
                candidate = binding.UpdateState( ...
                    candidate, payload, obj.Context);
            end
        end
        labkit.app.internal.runtime.RuntimeContractBoundary.validateState( ...
            obj.Application, candidate);
        view = obj.present(candidate);
        if hasCallback
            obj.Recorder.checkpoint( ...
                "callback.presentation_started", ...
                "Native presentation commit started.", ...
                Category="runtime.callback", Audience="developer", ...
                Attributes=struct("runtimeAlias", binding.Id));
        end
        obj.Adapter.reconcile(previousPresentation, view);
        obj.State = candidate;
        obj.Presentation = view;
    catch cause
        obj.State = previousState;
        obj.Presentation = previousPresentation;
        failure = MException("labkit:app:runtime:ActionFailed", ...
            "%s failed transactionally.", failureLabel);
        failure = addCause(failure, cause);
        throwAsCaller(failure);
    end
end
