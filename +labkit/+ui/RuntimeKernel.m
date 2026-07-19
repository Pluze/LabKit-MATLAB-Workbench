classdef (Hidden, Sealed) RuntimeKernel < handle
    % Private transactional runtime for compiled Application values.
    properties (SetAccess = private)
        State (1, 1) struct
        Presentation
        StatusLog (1, :) string = strings(1, 0)
        Diagnostics (1, :) cell = {}
        Closed (1, 1) logical = false
    end

    properties (Access = private)
        Application
        Context
        Queue (1, :) cell = {}
        Processing (1, 1) logical = false
        Resources
        Adapter
        Documents
    end

    methods (Access = ?labkit.ui.Application)
        function obj = RuntimeKernel(application, initialProject, backend)
            obj.Application = application;
            obj.Resources = labkit.ui.ResourceStore();
            obj.Adapter = labkit.ui.HeadlessPlatformAdapter();
            if ~isempty(application.Project)
                obj.Documents = labkit.ui.ProjectDocumentStore(application);
            end
            backend = obj.completeBackend(backend);
            obj.Context = labkit.ui.RuntimeContext.createForRuntime( ...
                application, backend);
            project = obj.initialProject(initialProject);
            session = struct();
            if ~isempty(application.Session)
                session = application.Session(project);
            end
            if ~isstruct(session) || ~isscalar(session)
                error("labkit:ui:runtime:InvariantFailure", ...
                    "Application Session must return a scalar struct.");
            end
            obj.State = struct("project", project, "session", session);
            obj.validateState(obj.State);
            obj.Presentation = obj.present(obj.State);
            obj.Adapter.reconcile([], obj.Presentation);
            if ~isempty(application.Start)
                obj.dispatch(application.Start, []);
            end
        end
    end

    methods
        function dispatch(obj, command, payload)
            obj.assertOpen();
            obj.validateDispatch(command, payload);
            obj.Queue{end + 1} = struct( ...
                "Command", command, "Payload", payload);
            if obj.Processing
                return;
            end
            obj.Processing = true;
            cleanup = onCleanup(@() obj.finishProcessing());
            while ~isempty(obj.Queue)
                item = obj.Queue{1};
                obj.Queue(1) = [];
                obj.execute(item.Command, item.Payload);
            end
            clear cleanup
        end

        function setResource(obj, scope, id, value, cleanup)
            obj.Resources.set(scope, id, value, cleanup);
        end

        function value = getResource(obj, scope, id)
            value = obj.Resources.get(scope, id);
        end

        function removeResource(obj, scope, id)
            obj.Resources.remove(scope, id);
        end

        function clearResourceScope(obj, scope)
            obj.Resources.clearScope(scope);
        end

        function failNextCommit(obj)
            obj.Adapter.failNextCommit();
        end

        function count = commitCount(obj)
            count = obj.Adapter.CommitCount;
        end

        function result = saveProject(obj, state, filepath)
            obj.assertProjectStore();
            result = obj.Documents.save(state, filepath);
        end

        function saveRecovery(obj, state, filepath)
            obj.assertProjectStore();
            obj.Documents.saveRecovery(state, filepath);
        end

        function restoreProject(obj, filepath, asRecovery)
            if nargin < 3
                asRecovery = false;
            end
            obj.assertOpen();
            obj.assertProjectStore();
            previousState = obj.State;
            previousPresentation = obj.Presentation;
            [candidate, metadata] = obj.Documents.restore(filepath, asRecovery);
            try
                obj.validateState(candidate);
                view = obj.present(candidate);
                obj.Adapter.reconcile(previousPresentation, view);
                obj.State = candidate;
                obj.Presentation = view;
                obj.Documents.acceptRestore(metadata);
            catch cause
                obj.State = previousState;
                obj.Presentation = previousPresentation;
                failure = MException( ...
                    "labkit:ui:runtime:ProjectRestoreFailed", ...
                    "Project restore failed transactionally.");
                failure = addCause(failure, cause);
                throwAsCaller(failure);
            end
        end

        function metadata = documentMetadata(obj)
            obj.assertProjectStore();
            metadata = obj.Documents.Metadata;
        end

        function written = writeResult(obj, folder, result)
            metadata = [];
            if ~isempty(obj.Documents)
                metadata = obj.Documents.Metadata;
            end
            writer = labkit.ui.ResultWriter(obj.Application, metadata);
            written = writer.write(folder, result);
        end

        function close(obj)
            if obj.Closed
                return;
            end
            obj.Queue = {};
            obj.Closed = true;
            if ~isempty(obj.Resources)
                obj.Resources.clearAll();
            end
        end

        function delete(obj)
            obj.close();
        end
    end

    methods (Access = private)
        function backend = completeBackend(obj, backend)
            if nargin < 2 || isempty(backend)
                backend = struct();
            end
            builtins = struct( ...
                "dispatch", @(command, payload) obj.dispatch(command, payload), ...
                "appendStatus", @(state, message) ...
                    obj.appendStatus(state, message), ...
                "reportError", @(operation, exception) ...
                    obj.reportError(operation, exception), ...
                "setResource", @(scope, id, value, cleanup) ...
                    obj.setResource(scope, id, value, cleanup), ...
                "getResource", @(scope, id) obj.getResource(scope, id), ...
                "removeResource", @(scope, id) obj.removeResource(scope, id), ...
                "clearResourceScope", @(scope) obj.clearResourceScope(scope));
            builtins.saveProject = @(state, filepath) ...
                obj.saveProject(state, filepath);
            builtins.saveRecovery = @(state, filepath) ...
                obj.saveRecovery(state, filepath);
            builtins.writeResult = @(folder, result) ...
                obj.writeResult(folder, result);
            names = string(fieldnames(builtins));
            for k = 1:numel(names)
                backend.(names(k)) = builtins.(names(k));
            end
        end

        function project = initialProject(obj, supplied)
            if nargin >= 2 && ~isempty(supplied)
                project = supplied;
            elseif ~isempty(obj.Application.Project)
                project = obj.Application.Project.Create();
            else
                project = struct();
            end
            if ~isstruct(project) || ~isscalar(project)
                error("labkit:ui:runtime:InvariantFailure", ...
                    "Application project must be a scalar struct.");
            end
        end

        function execute(obj, command, payload)
            previousState = obj.State;
            previousPresentation = obj.Presentation;
            try
                if command.Role == "invoke"
                    candidate = command.Callback(previousState, obj.Context);
                else
                    candidate = command.Callback( ...
                        previousState, payload, obj.Context);
                end
                obj.validateState(candidate);
                view = obj.present(candidate);
                obj.Adapter.reconcile(previousPresentation, view);
                obj.State = candidate;
                obj.Presentation = view;
            catch cause
                obj.State = previousState;
                obj.Presentation = previousPresentation;
                obj.Resources.clearScope("event");
                failure = MException("labkit:ui:runtime:ActionFailed", ...
                    "Command %s failed transactionally.", command.Id);
                failure = addCause(failure, cause);
                throwAsCaller(failure);
            end
            obj.Resources.clearScope("event");
        end

        function validateDispatch(obj, command, payload)
            if ~isa(command, "labkit.ui.Command") || ...
                    ~obj.Application.hasCommandForRuntime(command)
                error("labkit:ui:contract:UnknownReference", ...
                    "Runtime dispatch Command is undeclared.");
            end
            if command.Role == "invoke" && ~isempty(payload)
                error("labkit:ui:contract:InvalidValue", ...
                    "Invoke Command payload must be empty.");
            end
            if strlength(command.PayloadClass) > 0 && ...
                    ~isa(payload, command.PayloadClass)
                error("labkit:ui:contract:InvalidValue", ...
                    "Command %s payload must be %s.", ...
                    command.Id, command.PayloadClass);
            end
        end

        function validateState(obj, state)
            if ~isstruct(state) || ~isscalar(state) || ...
                    ~all(isfield(state, ["project", "session"])) || ...
                    ~isstruct(state.project) || ~isscalar(state.project) || ...
                    ~isstruct(state.session) || ~isscalar(state.session)
                error("labkit:ui:runtime:InvariantFailure", ...
                    "Command must return scalar project/session state.");
            end
            if ~isempty(obj.Application.Project)
                accepted = obj.Application.Project.Validate(state.project);
                if ~(islogical(accepted) && isscalar(accepted) && accepted)
                    error("labkit:ui:runtime:InvariantFailure", ...
                        "Project validation rejected command state.");
                end
            end
        end

        function view = present(obj, state)
            if isempty(obj.Application.Present)
                view = labkit.ui.Presentation();
                if ~isempty(obj.Application.TargetIds)
                    error("labkit:ui:runtime:InvariantFailure", ...
                        "A nonstatic Application requires Present.");
                end
            else
                view = obj.Application.Present(state);
            end
            obj.Application.validatePresentation(view);
        end

        function state = appendStatus(obj, state, message)
            obj.StatusLog(end + 1) = message;
        end

        function reportError(obj, operation, exception)
            obj.Diagnostics{end + 1} = struct( ...
                "Operation", operation, "Exception", exception);
        end

        function finishProcessing(obj)
            obj.Processing = false;
        end

        function assertOpen(obj)
            if obj.Closed
                error("labkit:ui:runtime:InvariantFailure", ...
                    "Application runtime is closed.");
            end
        end

        function assertProjectStore(obj)
            if isempty(obj.Documents)
                error("labkit:ui:runtime:InvariantFailure", ...
                    "Application has no project contract.");
            end
        end
    end
end
