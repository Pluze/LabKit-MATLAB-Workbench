classdef (Hidden, Sealed) RuntimeKernel < handle
    % Private transactional runtime for compiled Application values.
    properties (SetAccess = private)
        State (1, 1) struct
        Presentation
        StatusLog (1, :) string = "Ready."
        Diagnostics (1, :) cell = {}
        Closed (1, 1) logical = false
        StartupFailed (1, 1) logical = false
    end

    properties (Access = private)
        Application
        Contract
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
                application, contract, initialProject, backend, platform, ...
                diagnostics, recorder)
            obj.Application = application;
            obj.Contract = contract;
            if nargin < 6
                diagnostics = labkit.app.diagnostic.Options();
            end
            if nargin < 7
                recorder = labkit.app.internal.DiagnosticRecorder( ...
                    application, diagnostics);
            end
            obj.Recorder = recorder;
            startupOperation = obj.Recorder.begin( ...
                "runtime.lifecycle", "runtime.construct", ...
                "Constructing application runtime.");
            obj.Resources = labkit.app.internal.ResourceStore();
            obj.Sources = labkit.app.internal.PortableSourceStore();
            if nargin < 4
                platform = "headless";
            end
            obj.Adapter = ...
                labkit.app.internal.RuntimeContractBoundary.createAdapter( ...
                obj.Application, obj.Contract, platform);
            try
                backend = obj.completeBackend(backend);
                obj.Context = ...
                    labkit.app.internal.CallbackContextFactory.create(backend);
                obj.updateStartup("Creating app state...");
                if ~isempty(application.ProjectSchema)
                    obj.Documents = labkit.app.internal.ProjectDocumentStore( ...
                        application, obj.Context, contract);
                end
                project = ...
                    labkit.app.internal.RuntimeContractBoundary.initialProject( ...
                    obj.Application, initialProject);
                session = struct();
                if ~isempty(application.CreateSession)
                    session = application.CreateSession(project, obj.Context);
                end
                if ~isstruct(session) || ~isscalar(session)
                    error("labkit:app:runtime:InvariantFailure", ...
                        "Application Session must return a scalar struct.");
                end
                obj.State = struct("project", project, "session", session);
                labkit.app.internal.RuntimeContractBoundary.validateState( ...
                    obj.Application, obj.State);
                obj.updateStartup("Preparing first view...");
                if isa(obj.Adapter, "labkit.app.internal.MatlabPlatformAdapter")
                    obj.Adapter.attachRuntime(obj);
                end
                obj.Presentation = obj.present(obj.State);
                obj.Adapter.reconcile([], obj.Presentation);
                if ~isempty(application.OnStart) && ...
                        diagnostics.Sample ~= "synthetic"
                    obj.updateStartup("Running startup actions...");
                    obj.dispatch( ...
                        contract.onStartBinding(), []);
                end
                obj.Recorder.finish( ...
                    startupOperation, "completed", "committed", []);
                if isa(obj.Adapter, "labkit.app.internal.MatlabPlatformAdapter")
                    obj.Adapter.finishStartup();
                end
            catch cause
                obj.Recorder.finish( ...
                    startupOperation, "failed", "notApplicable", cause);
                if isa(obj.Adapter, ...
                        "labkit.app.internal.MatlabPlatformAdapter")
                    obj.StartupFailed = true;
                    obj.Adapter.failStartup(cause);
                    return
                end
                obj.close();
                rethrow(cause);
            end
        end
    end

    methods
        function dispatch(obj, binding, payload)
            obj.assertOpen();
            labkit.app.internal.RuntimeContractBoundary.validateDispatch( ...
                obj.Contract, binding, payload);
            obj.Queue{end + 1} = struct( ...
                "Binding", binding, "Payload", {payload});
            if obj.Processing
                return;
            end
            obj.Processing = true;
            if isa(obj.Adapter, "labkit.app.internal.MatlabPlatformAdapter")
                obj.Adapter.beginBusy( ...
                    labkit.app.internal.RuntimeContractBoundary.busyMessage( ...
                    obj.Contract, binding));
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
                labkit.app.internal.RuntimeContractBoundary.validateState( ...
                    obj.Application, candidate);
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
            plan = obj.Contract.PlatformPlan;
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
                binding = ...
                    labkit.app.internal.RuntimeContractBoundary.signalForTarget( ...
                    obj.Contract, target, "valueChanged", false);
                if isempty(binding)
                    error("labkit:app:contract:UnknownReference", ...
                        "Layout target has no value behavior: %s.", target);
                end
                obj.dispatch(binding, value);
            end
        end

        function invokeAction(obj, target)
            obj.assertOpen();
            binding = ...
                labkit.app.internal.RuntimeContractBoundary.signalForTarget( ...
                obj.Contract, target, "pressed");
            obj.dispatch(binding, []);
        end

        function applyTableEdit(obj, target, edit)
            obj.assertOpen();
            if ~isa(edit, "labkit.app.event.TableCellEdit")
                error("labkit:app:contract:InvalidValue", ...
                    "Table edit payload must be a TableEdit value.");
            end
            binding = ...
                labkit.app.internal.RuntimeContractBoundary.signalForTarget( ...
                obj.Contract, target, "cellEdited");
            obj.dispatch(binding, edit);
        end

        function applyTableSelection(obj, target, cells)
            obj.assertOpen();
            selection = labkit.app.event.TableCellSelection(cells);
            binding = ...
                labkit.app.internal.RuntimeContractBoundary.signalForTarget( ...
                obj.Contract, target, "cellSelectionChanged");
            obj.dispatch(binding, selection);
        end

        function applyInteraction(obj, interactionId, signal, payload)
            obj.assertOpen();
            binding = ...
                labkit.app.internal.RuntimeContractBoundary.interactionSignal( ...
                obj.Contract, interactionId, signal);
            obj.dispatch(binding, payload);
        end

        function applyFilePanelSelection(obj, target, indices)
            obj.assertOpen();
            [config, current] = ...
                labkit.app.internal.RuntimeContractBoundary.fileListState( ...
                obj.Contract, obj.State, target);
            obj.commitFilePanel(target, config, current, indices, false);
        end

        function applyBoundControl(obj, target, value, dispatchChanged)
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
                candidate = labkit.app.internal.RuntimeStatePath.write( ...
                    previousState, path, value);
                if dispatchChanged
                    binding = ...
                        labkit.app.internal.RuntimeContractBoundary.signalForTarget( ...
                        obj.Contract, target, "valueChanged", false);
                    if ~isempty(binding)
                        candidate = binding.UpdateState( ...
                            candidate, value, obj.Context);
                    end
                end
                labkit.app.internal.RuntimeContractBoundary.validateState( ...
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

        function applyFileSelection(obj, target, paths, indices)
            obj.assertOpen();
            [config, current] = ...
                labkit.app.internal.RuntimeContractBoundary.fileListState( ...
                obj.Contract, obj.State, target);
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
            [config, current] = ...
                labkit.app.internal.RuntimeContractBoundary.fileListState( ...
                obj.Contract, obj.State, target);
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
            candidate = labkit.app.internal.RuntimeStatePath.write( ...
                obj.State, config.Bind, sources);
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
                candidate = labkit.app.internal.RuntimeStatePath.write( ...
                    candidate, config.SelectionBind, selection);
            else
                selection = labkit.app.event.ListSelection(Indices=indices);
            end
            binding = ...
                labkit.app.internal.RuntimeContractBoundary.signalForTarget( ...
                obj.Contract, target, "listSelectionChanged", false);
            if ~isempty(binding)
                candidate = binding.UpdateState( ...
                    candidate, selection, obj.Context);
            end
            previousState = obj.State;
            previousPresentation = obj.Presentation;
            try
                labkit.app.internal.RuntimeContractBoundary.validateState( ...
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
                    "fileList update for %s failed transactionally.", target);
                failure = addCause(failure, cause);
                throwAsCaller(failure);
            end
        end

        function backend = completeBackend(obj, backend)
            if nargin < 2 || isempty(backend)
                backend = struct();
            end
            builtins = struct( ...
                "log", @(severity, eventName, message, category, audience, attributes, exception) ...
                    obj.log(severity, eventName, message, category, audience, attributes, exception), ...
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

        function execute(obj, binding, payload)
            previousState = obj.State;
            previousPresentation = obj.Presentation;
            obj.PendingDocumentMetadata = [];
            operation = obj.Recorder.begin( ...
                "runtime.callback", "callback." + binding.Signal, ...
                "Dispatching callback.", Attributes=struct("bindingId", binding.Id));
            try
                if ~binding.AcceptsPayload
                    candidate = binding.UpdateState(previousState, obj.Context);
                else
                    candidate = binding.UpdateState( ...
                        previousState, payload, obj.Context);
                end
                labkit.app.internal.RuntimeContractBoundary.validateState( ...
                    obj.Application, candidate);
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
                obj.Recorder.finish(operation, "completed", "committed", []);
            catch cause
                obj.State = previousState;
                obj.Presentation = previousPresentation;
                obj.PendingDocumentMetadata = [];
                obj.Resources.clearScope("event");
                obj.Recorder.finish(operation, "failed", "rolledBack", cause);
                failure = MException("labkit:app:runtime:ActionFailed", ...
                    "Callback %s failed transactionally.", binding.Id);
                failure = addCause(failure, cause);
                throwAsCaller(failure);
            end
            obj.PendingDocumentMetadata = [];
            obj.Resources.clearScope("event");
        end

        function view = present(obj, state)
            view = labkit.app.internal.RuntimePresentation.fromState( ...
                obj.Contract.PlatformPlan, state, ...
                @(records, role) obj.presentationSourcePaths(records, role), ...
                obj.StatusLog);
            if isempty(obj.Application.PresentWorkbench)
                custom = labkit.app.view.Snapshot();
            else
                custom = obj.Application.PresentWorkbench(state);
            end
            view = view.overlayForRuntime(custom);
            obj.Application.validateViewSnapshot(view);
        end

        function appendStatus(obj, message)
            obj.StatusLog(end + 1) = message;
            try
                obj.Recorder.log("info", "status.appended", message, ...
                    Category="runtime.presentation", Audience="user");
            catch
                obj.Recorder.log("warning", "status.omitted", ...
                    "Status was omitted from diagnostics.", ...
                    Category="runtime.presentation", Audience="developer", ...
                    Attributes=struct("reason", "unsafe"));
            end
        end

        function paths = presentationSourcePaths(obj, records, role)
            records = obj.Sources.recordsForRole(records, role);
            paths = obj.Sources.sourcePaths(records);
        end

        function reportError(obj, operation, exception)
            obj.Diagnostics{end + 1} = struct( ...
                "Operation", operation, "Exception", exception);
            obj.Recorder.reportError(operation, exception);
        end

        function log(obj, severity, eventName, message, category, audience, attributes, exception)
            obj.Recorder.log(severity, eventName, message, ...
                Category=category, Audience=audience, Attributes=attributes, ...
                Exception=exception);
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
            if obj.StartupFailed
                error("labkit:app:runtime:StartupFailed", ...
                    "Application runtime did not complete startup.");
            end
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
