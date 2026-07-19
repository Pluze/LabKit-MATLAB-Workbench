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
        Sources
    end

    methods (Access = ?labkit.ui.Application)
        function obj = RuntimeKernel(application, initialProject, backend)
            obj.Application = application;
            obj.Resources = labkit.ui.ResourceStore();
            obj.Sources = labkit.ui.PortableSourceStore();
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

        function record = sourceRecord(obj, id, role, path, required)
            record = obj.Sources.create(id, role, path, required);
        end

        function paths = sourcePaths(obj, sources, ids)
            if isempty(ids)
                paths = obj.Sources.sourcePaths(sources);
            else
                paths = obj.Sources.sourcePaths(sources, ids);
            end
        end

        function sources = upsertSource(obj, sources, record)
            sources = obj.Sources.upsert(sources, record);
        end

        function sources = reconcileSources(obj, current, incoming)
            sources = obj.Sources.reconcile(current, incoming);
        end

        function applyBinding(obj, target, value)
            obj.assertOpen();
            plan = obj.Application.platformPlanForRuntime();
            index = find(string({plan.Nodes.Id}) == string(target), 1);
            if isempty(index) || ~isfield(plan.Nodes(index).Configuration, "Bind")
                error("labkit:ui:contract:UnknownReference", ...
                    "Layout target has no state binding: %s.", target);
            end
            path = plan.Nodes(index).Configuration.Bind;
            if strlength(path) == 0
                error("labkit:ui:contract:UnknownReference", ...
                    "Layout target has no state binding: %s.", target);
            end
            previousState = obj.State;
            previousPresentation = obj.Presentation;
            try
                candidate = setBoundValue(previousState, path, value);
                obj.validateState(candidate);
                view = obj.present(candidate);
                obj.Adapter.reconcile(previousPresentation, view);
                obj.State = candidate;
                obj.Presentation = view;
            catch cause
                obj.State = previousState;
                obj.Presentation = previousPresentation;
                failure = MException("labkit:ui:runtime:ActionFailed", ...
                    "Bound update for %s failed transactionally.", target);
                failure = addCause(failure, cause);
                throwAsCaller(failure);
            end
        end

        function applyFileSelection(obj, target, paths, indices)
            obj.assertOpen();
            plan = obj.Application.platformPlanForRuntime();
            index = find(string({plan.Nodes.Id}) == string(target), 1);
            if isempty(index) || plan.Nodes(index).Kind ~= "filePanel"
                error("labkit:ui:contract:UnknownReference", ...
                    "Layout target is not a filePanel: %s.", target);
            end
            config = plan.Nodes(index).Configuration;
            if strlength(config.Bind) == 0
                error("labkit:ui:contract:UnknownReference", ...
                    "filePanel target has no source binding: %s.", target);
            end
            current = getBoundValue(obj.State, config.Bind);
            sources = obj.Sources.reconcilePaths( ...
                current, paths, config.SourceRole, ...
                config.SourceIdPrefix, config.Required);
            if nargin < 4
                indices = 1:numel(sources);
            end
            if ~(isnumeric(indices) && isrow(indices) && ...
                    all(isfinite(indices)) && all(indices == fix(indices)) && ...
                    all(indices >= 1) && all(indices <= numel(sources)))
                error("labkit:ui:contract:InvalidValue", ...
                    "filePanel selection indices are invalid.");
            end
            candidate = setBoundValue(obj.State, config.Bind, sources);
            if strlength(config.SelectionBind) > 0
                ids = strings(1, 0);
                if ~isempty(indices)
                    ids = string({sources(indices).id});
                end
                selection = labkit.ui.Selection( ...
                    Ids=ids, Indices=indices);
                candidate = setBoundValue( ...
                    candidate, config.SelectionBind, selection);
            end
            previousState = obj.State;
            previousPresentation = obj.Presentation;
            try
                obj.validateState(candidate);
                view = obj.present(candidate);
                obj.Adapter.reconcile(previousPresentation, view);
                obj.State = candidate;
                obj.Presentation = view;
            catch cause
                obj.State = previousState;
                obj.Presentation = previousPresentation;
                failure = MException("labkit:ui:runtime:ActionFailed", ...
                    "filePanel update for %s failed transactionally.", target);
                failure = addCause(failure, cause);
                throwAsCaller(failure);
            end
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
                "appendStatus", @(message) obj.appendStatus(message), ...
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
            builtins.sourceRecord = @(id, role, path, required) ...
                obj.sourceRecord(id, role, path, required);
            builtins.sourcePaths = @(sources, ids) ...
                obj.sourcePaths(sources, ids);
            builtins.upsertSource = @(sources, record) ...
                obj.upsertSource(sources, record);
            builtins.reconcileSources = @(current, incoming) ...
                obj.reconcileSources(current, incoming);
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
            view = obj.defaultPresentation(state);
            if isempty(obj.Application.Present)
                custom = labkit.ui.Presentation();
            else
                custom = obj.Application.Present(state);
            end
            view = view.overlayForRuntime(custom);
            obj.Application.validatePresentation(view);
        end

        function view = defaultPresentation(obj, state)
            plan = obj.Application.platformPlanForRuntime();
            view = labkit.ui.Presentation();
            for k = 1:numel(plan.Nodes)
                node = plan.Nodes(k);
                if isempty(node.Capabilities)
                    continue;
                end
                config = node.Configuration;
                switch node.Kind
                    case "action"
                        view = view.enabled(node.Id, config.Enabled);
                    case {"field", "rangeField", "panner"}
                        value = config.Value;
                        if isfield(config, "Bind") && ...
                                strlength(config.Bind) > 0
                            value = getBoundValue(state, config.Bind);
                        end
                        view = view.value(node.Id, value);
                    case "filePanel"
                        paths = strings(0, 1);
                        if isfield(config, "Bind") && ...
                                strlength(config.Bind) > 0
                            sources = getBoundValue(state, config.Bind);
                            paths = obj.Sources.sourcePaths(sources);
                        end
                        view = view.files(node.Id, paths);
                    case "previewArea"
                        view = view.visible(node.Id, true);
                    case "resultTable"
                        view = view.table(node.Id, table());
                    case {"logPanel", "statusPanel"}
                        view = view.text(node.Id, "");
                    case "workspacePage"
                        view = view.workspacePage(node.Id);
                    otherwise
                        error("labkit:ui:runtime:InvariantFailure", ...
                            "No default presentation for Layout kind %s.", ...
                            node.Kind);
                end
            end
        end

        function appendStatus(obj, message)
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

function value = getBoundValue(state, path)
    parts = split(path, ".");
    value = state;
    for k = 1:numel(parts)
        name = char(parts(k));
        if ~isstruct(value) || ~isscalar(value) || ~isfield(value, name)
            error("labkit:ui:contract:UnknownReference", ...
                "Binding path is absent from state: %s.", path);
        end
        value = value.(name);
    end
end

function state = setBoundValue(state, path, value)
    parts = cellstr(split(path, "."));
    state = assignField(state, parts, value, path);
end

function owner = assignField(owner, parts, value, path)
    name = parts{1};
    if ~isstruct(owner) || ~isscalar(owner) || ~isfield(owner, name)
        error("labkit:ui:contract:UnknownReference", ...
            "Binding path is absent from state: %s.", path);
    end
    if numel(parts) == 1
        owner.(name) = value;
    else
        owner.(name) = assignField(owner.(name), parts(2:end), value, path);
    end
end
