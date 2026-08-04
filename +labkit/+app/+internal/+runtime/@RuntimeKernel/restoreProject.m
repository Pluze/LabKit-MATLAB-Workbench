function restoreProject(obj, filepath, asRecovery)
%RESTOREPROJECT Commit one restored project and presentation atomically.
    if nargin < 3
        asRecovery = false;
    end
    obj.assertOpen();
    obj.assertProjectStore();
    previousState = obj.State;
    previousPresentation = obj.Presentation;
    operation = obj.Recorder.begin( ...
        "runtime.project", "project.restored", ...
        "Restoring project document.");
    try
        [candidate, metadata] = ...
            obj.Documents.restore(filepath, asRecovery);
    catch cause
        obj.Recorder.finish( ...
            operation, "failed", "notApplicable", cause);
        rethrow(cause);
    end
    try
        labkit.app.internal.runtime.RuntimeContractBoundary.validateState( ...
            obj.Application, candidate);
        view = obj.present(candidate);
        obj.Adapter.reconcile(previousPresentation, view);
        obj.State = candidate;
        obj.Presentation = view;
        obj.Documents.acceptRestore(metadata);
        obj.refreshWindowTitle();
        obj.Recorder.finish( ...
            operation, "completed", "committed", []);
    catch cause
        obj.State = previousState;
        obj.Presentation = previousPresentation;
        obj.Recorder.finish( ...
            operation, "failed", "rolledBack", cause);
        failure = MException( ...
            "labkit:app:runtime:ProjectRestoreFailed", ...
            "Project restore failed transactionally.");
        failure = addCause(failure, cause);
        throwAsCaller(failure);
    end
end
