classdef (Hidden, Sealed) RuntimeKernel < handle
    % Private transactional runtime for compiled Application values.
    properties (SetAccess = private)
        State (1, 1) struct
        Presentation
        StatusLog (1, :) string = "Ready."
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
        Recorder
        PendingDocumentMetadata = []
    end

    methods (Access = ?labkit.app.internal.RuntimeFactory)
        function obj = RuntimeKernel( ...
                application, initialProject, backend, platform, diagnostics, ...
                recorder)
            obj.Application = application;
            if nargin < 5
                diagnostics = labkit.app.diagnostic.Options();
            end
            if nargin < 6
                recorder = labkit.app.internal.DiagnosticRecorder( ...
                    application, diagnostics);
            end
            obj.Recorder = recorder;
            startupOperation = obj.Recorder.begin( ...
                "lifecycle", "runtime", "construct");
            obj.Resources = labkit.app.internal.ResourceStore();
            obj.Sources = labkit.app.internal.PortableSourceStore();
            if nargin < 4
                platform = "headless";
            end
            obj.Adapter = obj.createAdapter(platform);
            try
                backend = obj.completeBackend(backend);
                obj.Context = ...
                    labkit.app.internal.CallbackContextFactory.create(backend);
                obj.updateStartup("Creating app state...");
                if ~isempty(application.ProjectSchema)
                    obj.Documents = labkit.app.internal.ProjectDocumentStore( ...
                        application, obj.Context);
                end
                project = obj.initialProject(initialProject);
                session = struct();
                if ~isempty(application.CreateSession)
                    session = application.CreateSession(project, obj.Context);
                end
                if ~isstruct(session) || ~isscalar(session)
                    error("labkit:app:runtime:InvariantFailure", ...
                        "Application Session must return a scalar struct.");
                end
                obj.State = struct("project", project, "session", session);
                obj.validateState(obj.State);
                obj.updateStartup("Preparing first view...");
                if isa(obj.Adapter, "labkit.app.internal.MatlabPlatformAdapter")
                    obj.Adapter.attachRuntime(obj);
                end
                obj.Presentation = obj.present(obj.State);
                obj.Adapter.reconcile([], obj.Presentation);
                if ~isempty(application.OnStart)
                    obj.updateStartup("Running startup actions...");
                    obj.dispatch( ...
                        application.onStartBindingForRuntime(), []);
                end
                obj.Recorder.finish( ...
                    startupOperation, "completed", []);
                if isa(obj.Adapter, "labkit.app.internal.MatlabPlatformAdapter")
                    obj.Adapter.finishStartup();
                end
            catch cause
                obj.Recorder.finish( ...
                    startupOperation, "failed", cause);
                obj.close();
                rethrow(cause);
            end
        end
    end

    methods
        function dispatch(obj, binding, payload)
            obj.assertOpen();
            obj.validateDispatch(binding, payload);
            obj.Queue{end + 1} = struct( ...
                "Binding", binding, "Payload", {payload});
            if obj.Processing
                return;
            end
            obj.Processing = true;
            if isa(obj.Adapter, "labkit.app.internal.MatlabPlatformAdapter")
                obj.Adapter.beginBusy(obj.busyMessage(binding));
            end
            cleanup = onCleanup(@() obj.finishProcessing());
            while ~isempty(obj.Queue)
                item = obj.Queue{1};
                obj.Queue(1) = [];
                obj.execute(item.Binding, item.Payload);
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

        function events = diagnosticEvents(obj)
            events = obj.Recorder.events();
        end

        function folder = diagnosticFolder(obj)
            folder = obj.Recorder.artifactFolder();
        end

        function figure = figureHandle(obj)
            if ~isa(obj.Adapter, "labkit.app.internal.MatlabPlatformAdapter")
                error("labkit:app:runtime:InvariantFailure", ...
                    "Headless runtime has no MATLAB figure.");
            end
            figure = obj.Adapter.figureForRuntime();
        end

        function showFigure(obj)
            if isa(obj.Adapter, "labkit.app.internal.MatlabPlatformAdapter")
                obj.Adapter.show(obj.formattedWindowTitle());
            end
        end

        function result = saveProject(obj, state, filepath)
            obj.assertProjectStore();
            result = obj.Documents.save(state, filepath);
            obj.refreshWindowTitle();
        end

        function state = prepareProjectRestore(obj, filepath)
            obj.assertOpen();
            obj.assertProjectStore();
            [state, obj.PendingDocumentMetadata] = ...
                obj.Documents.restore(filepath, false);
        end

        function state = prepareNewProject(obj)
            obj.assertOpen();
            obj.assertProjectStore();
            [state, obj.PendingDocumentMetadata] = obj.Documents.createNew();
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
                obj.refreshWindowTitle();
            catch cause
                obj.State = previousState;
                obj.Presentation = previousPresentation;
                failure = MException( ...
                    "labkit:app:runtime:ProjectRestoreFailed", ...
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
            writer = labkit.app.internal.ResultWriter(obj.Application, metadata);
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
            obj.applyBoundControl(target, value, false);
        end

        function applyControlValue(obj, target, value)
            plan = obj.Application.platformPlanForRuntime();
            index = find(string({plan.Nodes.Id}) == string(target), 1);
            if isempty(index)
                error("labkit:app:contract:UnknownReference", ...
                    "Layout target is undeclared: %s.", target);
            end
            configuration = plan.Nodes(index).Configuration;
            if isfield(configuration, "Bind") && ...
                    strlength(configuration.Bind) > 0
                obj.applyBoundControl(target, value, true);
            else
                binding = obj.signalForTarget( ...
                    target, "valueChanged", false);
                if isempty(binding)
                    error("labkit:app:contract:UnknownReference", ...
                        "Layout target has no value behavior: %s.", target);
                end
                obj.dispatch(binding, value);
            end
        end

        function invokeAction(obj, target)
            obj.assertOpen();
            binding = obj.signalForTarget(target, "pressed");
            obj.dispatch(binding, []);
        end

        function applyTableEdit(obj, target, edit)
            obj.assertOpen();
            if ~isa(edit, "labkit.app.event.TableCellEdit")
                error("labkit:app:contract:InvalidValue", ...
                    "Table edit payload must be a TableEdit value.");
            end
            binding = obj.signalForTarget(target, "cellEdited");
            obj.dispatch(binding, edit);
        end

        function applyTableSelection(obj, target, cells)
            obj.assertOpen();
            selection = labkit.app.event.TableCellSelection(cells);
            binding = obj.signalForTarget(target, "cellSelectionChanged");
            obj.dispatch(binding, selection);
        end

        function applyInteraction(obj, interactionId, signal, payload)
            obj.assertOpen();
            binding = obj.interactionSignal(interactionId, signal);
            obj.dispatch(binding, payload);
        end

        function applyFilePanelSelection(obj, target, indices)
            obj.assertOpen();
            [config, current] = obj.fileListState(target);
            obj.commitFilePanel(target, config, current, indices, false);
        end

        function applyBoundControl(obj, target, value, dispatchChanged)
            obj.assertOpen();
            if nargin < 4
                dispatchChanged = false;
            end
            plan = obj.Application.platformPlanForRuntime();
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
                candidate = setBoundValue(previousState, path, value);
                if dispatchChanged
                    binding = obj.signalForTarget( ...
                        target, "valueChanged", false);
                    if ~isempty(binding)
                        candidate = binding.UpdateState( ...
                            candidate, value, obj.Context);
                    end
                end
                obj.validateState(candidate);
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

        function applyFileSelection(obj, target, paths, indices)
            obj.assertOpen();
            [config, current] = obj.fileListState(target);
            sources = obj.Sources.reconcileRolePaths( ...
                current, paths, config.SourceRole, ...
                config.SourceIdPrefix, config.Required, ...
                config.AllowDuplicatePaths);
            visibleSources = obj.Sources.recordsForRole( ...
                sources, config.SourceRole);
            if nargin < 4
                indices = 1:numel(visibleSources);
            end
            if ~(isnumeric(indices) && isrow(indices) && ...
                    all(isfinite(indices)) && all(indices == fix(indices)) && ...
                    all(indices >= 1) && ...
                    all(indices <= numel(visibleSources)))
                error("labkit:app:contract:InvalidValue", ...
                    "fileList selection indices are invalid.");
            end
            obj.commitFilePanel(target, config, sources, indices, true);
        end

        function removeFileSelection(obj, target, indices)
            obj.assertOpen();
            [config, current] = obj.fileListState(target);
            visible = obj.Sources.recordsForRole( ...
                current, config.SourceRole);
            if ~(isnumeric(indices) && isrow(indices) && ...
                    all(isfinite(indices)) && all(indices == fix(indices)) && ...
                    all(indices >= 1) && all(indices <= numel(visible)))
                error("labkit:app:contract:InvalidValue", ...
                    "fileList removal indices are invalid.");
            end
            keep = true(1, numel(visible));
            keep(indices) = false;
            sources = obj.Sources.replaceRole( ...
                current, config.SourceRole, visible(keep));
            obj.commitFilePanel( ...
                target, config, sources, zeros(1, 0), true);
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
            if ~isempty(obj.Adapter) && isvalid(obj.Adapter)
                obj.Adapter.close();
            end
            if ~isempty(obj.Recorder)
                obj.Recorder.close();
            end
        end

        function delete(obj)
            obj.close();
        end
    end

    methods (Access = private)
        function binding = interactionSignal(obj, interactionId, signal)
            plan = obj.Application.platformPlanForRuntime();
            binding = [];
            for k = 1:numel(plan.Nodes)
                config = plan.Nodes(k).Configuration;
                if ~isfield(config, "Interactions")
                    continue;
                end
                interactions = config.Interactions;
                match = find(cellfun(@(value) ...
                    value.Id == string(interactionId), interactions), 1);
                if ~isempty(match)
                    binding = interactions{match}.signal(string(signal));
                    break;
                end
            end
            if isempty(binding)
                error("labkit:app:contract:UnknownReference", ...
                    "Interaction %s has no %s callback.", ...
                    interactionId, signal);
            end
        end

        function binding = signalForTarget(obj, target, signal, required)
            if nargin < 4
                required = true;
            end
            plan = obj.Application.platformPlanForRuntime();
            index = find(string({plan.Nodes.Id}) == string(target), 1);
            binding = [];
            if ~isempty(index)
                signals = plan.Nodes(index).Signals;
                match = find(cellfun( ...
                    @(value) value.Signal == signal, signals), 1);
                if ~isempty(match)
                    binding = signals{match};
                end
            end
            if required && isempty(binding)
                error("labkit:app:contract:UnknownReference", ...
                    "Workbench target has no %s callback: %s.", ...
                    signal, target);
            end
        end

        function [config, current] = fileListState(obj, target)
            plan = obj.Application.platformPlanForRuntime();
            index = find(string({plan.Nodes.Id}) == string(target), 1);
            if isempty(index) || plan.Nodes(index).Kind ~= "fileList"
                error("labkit:app:contract:UnknownReference", ...
                    "Layout target is not a fileList: %s.", target);
            end
            config = plan.Nodes(index).Configuration;
            if strlength(config.Bind) == 0
                error("labkit:app:contract:UnknownReference", ...
                    "fileList target has no source binding: %s.", target);
            end
            current = getBoundValue(obj.State, config.Bind);
        end

        function commitFilePanel(obj, target, config, sources, indices, rebuildSession)
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
            candidate = setBoundValue(obj.State, config.Bind, sources);
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
                candidate = setBoundValue( ...
                    candidate, config.SelectionBind, selection);
            else
                selection = labkit.app.event.ListSelection(Indices=indices);
            end
            binding = obj.signalForTarget( ...
                target, "listSelectionChanged", false);
            if ~isempty(binding)
                candidate = binding.UpdateState( ...
                    candidate, selection, obj.Context);
            end
            previousState = obj.State;
            previousPresentation = obj.Presentation;
            try
                obj.validateState(candidate);
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

        function adapter = createAdapter(obj, platform)
            if ~(ischar(platform) || ...
                    (isstring(platform) && isscalar(platform)))
                error("labkit:app:runtime:InvariantFailure", ...
                    "Runtime platform must be scalar text.");
            end
            switch string(platform)
                case "headless"
                    adapter = labkit.app.internal.HeadlessPlatformAdapter();
                case "matlab"
                    plan = obj.Application.platformPlanForRuntime();
                    title = obj.Application.Title + " v" + ...
                        obj.Application.AppVersion + " (" + ...
                        obj.Application.Updated + ")";
                    if ~isempty(obj.Application.ProjectSchema)
                        title = title + " *";
                    end
                    adapter = labkit.app.internal.MatlabPlatformAdapter( ...
                        plan, title);
                otherwise
                    error("labkit:app:runtime:InvariantFailure", ...
                        "Runtime platform is unsupported: %s.", platform);
            end
        end

        function backend = completeBackend(obj, backend)
            if nargin < 2 || isempty(backend)
                backend = struct();
            end
            builtins = struct( ...
                "appendStatus", @(message) obj.appendStatus(message), ...
                "reportError", @(operation, exception) ...
                    obj.reportError(operation, exception), ...
                "diagnosticCheckpoint", @(id) ...
                    obj.Recorder.note( ...
                    "app", id, "checkpoint", "completed"), ...
                "diagnosticCount", @(id, count) ...
                    obj.Recorder.count(id, count), ...
                "setResource", @(scope, id, value, cleanup) ...
                    obj.setResource(scope, id, value, cleanup), ...
                "getResource", @(scope, id) obj.getResource(scope, id), ...
                "removeResource", @(scope, id) obj.removeResource(scope, id), ...
                "clearResourceScope", @(scope) obj.clearResourceScope(scope));
            builtins.saveProject = @(state, filepath) ...
                obj.saveProject(state, filepath);
            builtins.restoreProject = @(filepath) ...
                obj.prepareProjectRestore(filepath);
            builtins.newProject = @() obj.prepareNewProject();
            builtins.saveRecovery = @(state, filepath) ...
                obj.saveRecovery(state, filepath);
            builtins.writeResult = @(folder, result) ...
                obj.writeResult(folder, result);
            builtins.sourcePaths = @(sources, ids) ...
                obj.sourcePaths(sources, ids);
            if isa(obj.Adapter, "labkit.app.internal.MatlabPlatformAdapter")
                builtins.alert = @(message, title) obj.Adapter.alert(message, title);
                builtins.choose = @(prompt, choices, title, ...
                    defaultChoice, cancelChoice) ...
                    obj.Adapter.chooseOption(prompt, choices, title, ...
                    defaultChoice, cancelChoice);
                builtins.chooseInputFile = @(filters, startPath) ...
                    obj.Adapter.chooseInputFile(filters, startPath);
                builtins.chooseInputFolder = @(startPath) ...
                    obj.Adapter.chooseInputFolder(startPath);
                builtins.chooseOutputFile = @(filters, startPath) ...
                    obj.Adapter.chooseOutputFile(filters, startPath);
                builtins.chooseOutputFolder = @(startPath) ...
                    obj.Adapter.chooseOutputFolder(startPath);
            end
            names = string(fieldnames(builtins));
            for k = 1:numel(names)
                if ~isfield(backend, names(k))
                    backend.(names(k)) = builtins.(names(k));
                end
            end
        end

        function project = initialProject(obj, supplied)
            if nargin >= 2 && ~isempty(supplied)
                project = supplied;
            elseif ~isempty(obj.Application.ProjectSchema)
                project = obj.Application.ProjectSchema.Create();
            else
                project = struct();
            end
            if ~isstruct(project) || ~isscalar(project)
                error("labkit:app:runtime:InvariantFailure", ...
                    "Application project must be a scalar struct.");
            end
        end

        function execute(obj, binding, payload)
            previousState = obj.State;
            previousPresentation = obj.Presentation;
            obj.PendingDocumentMetadata = [];
            operation = obj.Recorder.begin( ...
                "callback", binding.Id, binding.Signal);
            try
                if ~binding.AcceptsPayload
                    candidate = binding.UpdateState(previousState, obj.Context);
                else
                    candidate = binding.UpdateState( ...
                        previousState, payload, obj.Context);
                end
                obj.validateState(candidate);
                view = obj.present(candidate);
                obj.Adapter.reconcile(previousPresentation, view);
                obj.State = candidate;
                obj.Presentation = view;
                if isempty(obj.PendingDocumentMetadata)
                    obj.markDocumentChanged();
                else
                    obj.Documents.acceptRestore(obj.PendingDocumentMetadata);
                    obj.refreshWindowTitle();
                end
                obj.Recorder.finish(operation, "completed", []);
            catch cause
                obj.State = previousState;
                obj.Presentation = previousPresentation;
                obj.PendingDocumentMetadata = [];
                obj.Resources.clearScope("event");
                obj.Recorder.finish(operation, "rolledBack", cause);
                failure = MException("labkit:app:runtime:ActionFailed", ...
                    "Callback %s failed transactionally.", binding.Id);
                failure = addCause(failure, cause);
                throwAsCaller(failure);
            end
            obj.PendingDocumentMetadata = [];
            obj.Resources.clearScope("event");
        end

        function validateDispatch(obj, binding, payload)
            if ~isa(binding, "labkit.app.internal.SignalBinding") || ...
                    ~obj.Application.hasSignalForRuntime(binding)
                error("labkit:app:contract:UnknownReference", ...
                    "Runtime dispatch callback is undeclared.");
            end
            if ~binding.AcceptsPayload && ~isempty(payload)
                error("labkit:app:contract:InvalidValue", ...
                    "Callback %s does not accept a payload.", binding.Id);
            end
            if strlength(binding.PayloadClass) > 0 && ...
                    ~isa(payload, binding.PayloadClass)
                error("labkit:app:contract:InvalidValue", ...
                    "Callback %s payload must be %s.", ...
                    binding.Id, binding.PayloadClass);
            end
        end

        function validateState(obj, state)
            if ~isstruct(state) || ~isscalar(state) || ...
                    ~all(isfield(state, ["project", "session"])) || ...
                    ~isstruct(state.project) || ~isscalar(state.project) || ...
                    ~isstruct(state.session) || ~isscalar(state.session)
                error("labkit:app:runtime:InvariantFailure", ...
                    "Command must return scalar project/session state.");
            end
            if ~isempty(obj.Application.ProjectSchema)
                accepted = obj.Application.ProjectSchema.Validate(state.project);
                if ~(islogical(accepted) && isscalar(accepted) && accepted)
                    error("labkit:app:runtime:InvariantFailure", ...
                        "Project validation rejected command state.");
                end
            end
        end

        function view = present(obj, state)
            view = obj.defaultPresentation(state);
            if isempty(obj.Application.PresentWorkbench)
                custom = labkit.app.view.Snapshot();
            else
                custom = obj.Application.PresentWorkbench(state);
            end
            view = view.overlayForRuntime(custom);
            obj.Application.validateViewSnapshot(view);
        end

        function view = defaultPresentation(obj, state)
            plan = obj.Application.platformPlanForRuntime();
            view = labkit.app.view.Snapshot();
            for k = 1:numel(plan.Nodes)
                node = plan.Nodes(k);
                if isempty(node.Capabilities)
                    continue;
                end
                config = node.Configuration;
                switch node.Kind
                    case "button"
                        view = view.enabled(node.Id, config.Enabled);
                    case "field"
                        value = neutralControlValue( ...
                            config.Value, config.Kind, config.Choices);
                        if strlength(config.Bind) > 0
                            value = getBoundValue(state, config.Bind);
                        end
                        view = view.value(node.Id, value);
                        if ~isempty(config.Choices)
                            view = view.choices(node.Id, config.Choices);
                        end
                        if ~isempty(config.Limits)
                            view = view.limits(node.Id, config.Limits);
                        end
                        view = view.enabled(node.Id, config.Enabled);
                    case "rangeField"
                        limits = config.Limits;
                        if isempty(limits)
                            limits = [0 1];
                        end
                        value = config.Value;
                        if isempty(value)
                            value = limits;
                        end
                        if strlength(config.Bind) > 0
                            value = getBoundValue(state, config.Bind);
                        end
                        view = view.value(node.Id, value);
                        view = view.limits(node.Id, limits);
                        view = view.enabled(node.Id, config.Enabled);
                    case "slider"
                        value = config.Value;
                        if strlength(config.Bind) > 0
                            value = getBoundValue(state, config.Bind);
                        end
                        view = view.value(node.Id, value);
                        if ~isempty(config.Limits)
                            view = view.limits(node.Id, config.Limits);
                        end
                        view = view.enabled(node.Id, config.Enabled);
                    case "fileList"
                        paths = strings(0, 1);
                        if strlength(config.Bind) > 0
                            sources = getBoundValue(state, config.Bind);
                            sources = obj.Sources.recordsForRole( ...
                                sources, config.SourceRole);
                            paths = obj.Sources.sourcePaths(sources);
                        end
                        view = view.filePaths(node.Id, paths);
                        if strlength(config.SelectionBind) > 0
                            selection = getBoundValue( ...
                                state, config.SelectionBind);
                            view = view.listSelection(node.Id, selection);
                        end
                    case "plotArea"
                        view = view.visible(node.Id, true);
                    case "dataTable"
                        view = view.tableData(node.Id, cell(0, 0), ...
                            Columns=config.Columns, ...
                            RowNames=config.RowNames, ...
                            ColumnEditable=config.ColumnEditable);
                    case "logPanel"
                        view = view.text(node.Id, ...
                            join(obj.StatusLog, newline));
                    case "statusPanel"
                        status = config.Text;
                        if isempty(status) && ~isempty(obj.StatusLog)
                            status = obj.StatusLog(end);
                        end
                        status = join(status, newline);
                        view = view.text(node.Id, status);
                    case "workspacePage"
                        view = view.workspacePage(node.Id);
                    otherwise
                        error("labkit:app:runtime:InvariantFailure", ...
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
            diagnosticOperation = obj.Recorder.begin( ...
                "reportedError", operation, "reported");
            obj.Recorder.finish( ...
                diagnosticOperation, "reported", exception);
        end

        function finishProcessing(obj)
            obj.Processing = false;
            if isa(obj.Adapter, "labkit.app.internal.MatlabPlatformAdapter")
                obj.Adapter.endBusy();
            end
        end

        function updateStartup(obj, message)
            if isa(obj.Adapter, "labkit.app.internal.MatlabPlatformAdapter")
                obj.Adapter.startupUpdate(message);
            end
        end

        function message = busyMessage(obj, binding)
            message = extractBefore(binding.Id, "__");
            plan = obj.Application.platformPlanForRuntime();
            index = find(string({plan.Nodes.Id}) == message, 1);
            if isempty(index)
                return
            end
            config = plan.Nodes(index).Configuration;
            if isfield(config, "BusyMessage") && ...
                    strlength(config.BusyMessage) > 0
                message = config.BusyMessage;
            elseif isfield(config, "Label") && strlength(config.Label) > 0
                message = config.Label;
            end
        end

        function markDocumentChanged(obj)
            if isempty(obj.Documents)
                return
            end
            obj.Documents.markDirty();
            obj.refreshWindowTitle();
        end

        function refreshWindowTitle(obj)
            if isa(obj.Adapter, "labkit.app.internal.MatlabPlatformAdapter")
                obj.Adapter.setWindowTitle(obj.formattedWindowTitle());
            end
        end

        function title = formattedWindowTitle(obj)
            title = obj.Application.Title + " v" + ...
                obj.Application.AppVersion + " (" + ...
                obj.Application.Updated + ")";
            if ~isempty(obj.Documents) && obj.Documents.Metadata.dirty
                title = title + " *";
            end
        end

        function assertOpen(obj)
            if obj.Closed
                error("labkit:app:runtime:InvariantFailure", ...
                    "Application runtime is closed.");
            end
        end

        function assertProjectStore(obj)
            if isempty(obj.Documents)
                error("labkit:app:runtime:InvariantFailure", ...
                    "Application has no project contract.");
            end
        end
    end
end

function value = neutralControlValue(value, kind, choices)
if ~isempty(value)
    return;
end
switch kind
    case "numeric"
        value = 0;
    case "choice"
        if isempty(choices)
            value = "";
        else
            value = choices(1);
        end
    case "logical"
        value = false;
    otherwise
        value = "";
end
end

function value = getBoundValue(state, path)
    parts = split(path, ".");
    value = state;
    for k = 1:numel(parts)
        name = char(parts(k));
        if ~isstruct(value) || ~isscalar(value) || ~isfield(value, name)
            error("labkit:app:contract:UnknownReference", ...
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
        error("labkit:app:contract:UnknownReference", ...
            "Binding path is absent from state: %s.", path);
    end
    if numel(parts) == 1
        owner.(name) = value;
    else
        owner.(name) = assignField(owner.(name), parts(2:end), value, path);
    end
end
