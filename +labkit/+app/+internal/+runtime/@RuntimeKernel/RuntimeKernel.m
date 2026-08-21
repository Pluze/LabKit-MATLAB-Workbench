classdef (Hidden, Sealed) RuntimeKernel < handle
    % Private transactional runtime for compiled Application values.
    properties (SetAccess = private)
        State (1, 1) struct
        Presentation
        CurrentStatus (1, 1) string = "Ready."
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
        Sources
        Recorder
        Artifacts
        Diagnostics
        PostedEvents
    end

    methods (Access = ?labkit.app.internal.runtime.RuntimeFactory)
        function obj = RuntimeKernel( ...
                application, contract, initialState, backend, platform, ...
                recorder)
            obj.Application = application;
            obj.Contract = contract;
            if ~isa(recorder, "labkit.app.internal.diagnostics.SessionDiagnostics") || ...
                    ~isscalar(recorder)
                error("labkit:app:runtime:InvariantFailure", ...
                    "RuntimeKernel requires one SessionDiagnostics service.");
            end
            obj.Recorder = recorder;
            obj.Artifacts = ...
                labkit.app.internal.artifact.Store(application.AppId);
            startupOperation = obj.Recorder.begin( ...
                "runtime.lifecycle", "runtime.construct", ...
                "Constructing application runtime.");
            obj.Resources = labkit.app.internal.resource.ResourceStore();
            obj.Sources = labkit.app.internal.source.SourceListStore();
            obj.PostedEvents = ...
                labkit.app.internal.runtime.PostedEventQueue( ...
                @(eventId, updateState) ...
                obj.dispatchPostedEvent(eventId, updateState));
            if nargin < 4
                platform = "headless";
            end
            obj.Adapter = ...
                labkit.app.internal.runtime.RuntimeContractBoundary.createAdapter( ...
                obj.Application, obj.Contract, platform);
            try
                backend = obj.completeBackend(backend);
                obj.Context = ...
                    labkit.app.internal.runtime.CallbackContextFactory.create(backend);
                obj.Diagnostics = ...
                    labkit.app.internal.diagnostics.RuntimeDiagnostics( ...
                    obj.Recorder, obj.Context, obj.Artifacts, ...
                    obj.Application.DisplayName, ...
                    @(message, title) obj.notifyUser(message, title));
                obj.updateStartup("Creating app state...");
                obj.State = ...
                    labkit.app.internal.runtime.RuntimeContractBoundary.initialState( ...
                    obj.Application, initialState, obj.Context);
                labkit.app.internal.runtime.RuntimeContractBoundary.validateState( ...
                    obj.Application, obj.State);
                obj.updateStartup("Preparing first view...");
                if isa(obj.Adapter, "labkit.app.internal.native.MatlabPlatformAdapter")
                    obj.Adapter.attachRuntime(obj);
                end
                obj.Presentation = obj.present(obj.State);
                obj.Adapter.reconcile([], obj.Presentation);
                if ~isempty(application.OnStart)
                    obj.updateStartup("Running startup actions...");
                    obj.dispatch( ...
                        contract.onStartBinding(), []);
                end
                obj.Recorder.finish( ...
                    startupOperation, "completed", "committed", []);
                if isa(obj.Adapter, "labkit.app.internal.native.MatlabPlatformAdapter")
                    obj.Adapter.finishStartup();
                end
            catch cause
                obj.Recorder.finish( ...
                    startupOperation, "failed", "notApplicable", cause);
                if isa(obj.Adapter, ...
                        "labkit.app.internal.native.MatlabPlatformAdapter")
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
            obj.enqueueTransition( ...
                binding, payload, @(state) state, ...
                "Callback " + binding.Id, ...
                labkit.app.internal.runtime.RuntimeContractBoundary.busyMessage( ...
                obj.Contract, binding));
        end

        function setResource(obj, scope, id, value, cleanup)
            obj.recordOperation( ...
                "runtime.resource", "resource.set", ...
                "Setting runtime resource.", ...
                "committed", "notApplicable", ...
                @() obj.Resources.set(scope, id, value, cleanup));
        end

        function value = getResource(obj, scope, id)
            value = obj.Resources.get(scope, id);
        end

        function removeResource(obj, scope, id)
            obj.recordOperation( ...
                "runtime.resource", "resource.removed", ...
                "Removing runtime resource.", ...
                "committed", "notApplicable", ...
                @() obj.Resources.remove(scope, id));
        end

        function clearResourceScope(obj, scope)
            obj.recordOperation( ...
                "runtime.resource", "resource.scope_cleared", ...
                "Clearing runtime resource scope.", ...
                "committed", "notApplicable", ...
                @() obj.Resources.clearScope(scope));
        end

        function postEvent(obj, eventId, updateState)
            if obj.Closed
                return;
            end
            if obj.Processing
                obj.PostedEvents.defer(eventId, updateState);
            else
                obj.PostedEvents.post(eventId, updateState);
            end
        end

        function failNextCommit(obj)
            obj.Adapter.failNextCommit();
        end

        function count = commitCount(obj)
            count = obj.Adapter.CommitCount;
        end

        function events = diagnosticEvents(obj)
            events = obj.Diagnostics.events();
        end

        function snapshot = diagnosticSnapshot(obj)
            snapshot = obj.Diagnostics.snapshot();
        end

        function title = sessionLogTitle(obj)
            title = obj.Diagnostics.title();
        end

        function token = subscribeDiagnostics(obj, callback)
            token = obj.Diagnostics.subscribe(callback);
        end

        function unsubscribeDiagnostics(obj, token)
            obj.Diagnostics.unsubscribe(token);
        end

        function setTraceCapture(obj, enabled)
            obj.Diagnostics.setTraceCapture(enabled);
        end

        function destination = exportDiagnosticBundle( ...
                obj, destination, stateMode)
            if nargin < 3
                stateMode = "compact";
            end
            destination = obj.Diagnostics.exportBundle( ...
                destination, obj.State, stateMode);
        end

        function destination = exportDiagnosticBundleInteractive(obj)
            destination = obj.Diagnostics.exportInteractive(obj.State);
        end

        function destination = exportDiagnosticTextFallback( ...
                obj, preferredDestination, cause, stateMode)
            if nargin < 4
                stateMode = "compact";
            end
            destination = obj.Diagnostics.exportTextFallback( ...
                preferredDestination, cause, stateMode);
        end

        function alertDiagnosticTextFallback(obj, destination)
            obj.Diagnostics.alertTextFallback(destination);
        end

        function supported = supportsSyntheticInputs(obj)
            supported = ~isempty(obj.Application.BuildSyntheticSample);
        end

        function pack = generateSyntheticInputs(obj, folder)
            operation = obj.Recorder.begin( ...
                "runtime.source", "synthetic_inputs.generated", ...
                "Generating synthetic inputs.");
            try
                pack = labkit.app.internal.source.SyntheticInputGenerator.generate( ...
                    obj.Application, folder);
                obj.Recorder.finish( ...
                    operation, "completed", "notApplicable", []);
            catch cause
                obj.Recorder.finish( ...
                    operation, "failed", "notApplicable", cause);
                rethrow(cause);
            end
        end

        function folder = generateSyntheticInputsInteractive(obj)
            choice = obj.Context.chooseOutputFolder("");
            folder = "";
            if choice.Cancelled
                return;
            end
            folder = obj.uniqueSyntheticInputFolder(choice.Value);
            obj.generateSyntheticInputs(folder);
            obj.Context.inform( ...
                "Synthetic inputs were written to the selected folder.", ...
                "Synthetic Inputs");
        end

        function destination = automaticArtifactDestination( ...
                obj, category, stem, extension)
            destination = obj.Artifacts.destination( ...
                category, stem, extension);
        end

        function filename = automaticArtifactFilename( ...
                obj, stem, extension)
            filename = obj.Artifacts.filename(stem, extension);
        end

        function figure = figureHandle(obj)
            if ~isa(obj.Adapter, "labkit.app.internal.native.MatlabPlatformAdapter")
                error("labkit:app:runtime:InvariantFailure", ...
                    "Headless runtime has no MATLAB figure.");
            end
            figure = obj.Adapter.figureForRuntime();
        end

        function showFigure(obj)
            if isa(obj.Adapter, "labkit.app.internal.native.MatlabPlatformAdapter")
                obj.Adapter.show(obj.formattedWindowTitle());
            end
        end

        function record = sourceRecord(obj, id, role, path, required)
            record = obj.recordOperation( ...
                "runtime.source", "source.record_created", ...
                "Creating source-list record.", ...
                "notApplicable", "notApplicable", ...
                @() obj.Sources.create(id, role, path, required));
        end

        function paths = sourcePaths(obj, sources, ids)
            paths = obj.recordOperation( ...
                "runtime.source", "source.paths_resolved", ...
                "Resolving source-list path paths.", ...
                "notApplicable", "notApplicable", ...
                @resolve);

            function values = resolve()
                if isempty(ids)
                    values = obj.Sources.sourcePaths(sources);
                else
                    values = obj.Sources.sourcePaths(sources, ids);
                end
            end
        end

        function sources = upsertSource(obj, sources, record)
            sources = obj.recordOperation( ...
                "runtime.source", "source.record_upserted", ...
                "Updating source-list records.", ...
                "notApplicable", "notApplicable", ...
                @() obj.Sources.upsert(sources, record));
        end

        function sources = reconcileSources(obj, current, incoming)
            sources = obj.recordOperation( ...
                "runtime.source", "source.records_reconciled", ...
                "Reconciling source-list records.", ...
                "notApplicable", "notApplicable", ...
                @() obj.Sources.reconcile(current, incoming));
        end

        function applyBinding(obj, target, value)
            obj.recordOperation( ...
                "runtime.interaction", "interaction.binding_applied", ...
                "Applying bound control value.", ...
                "committed", "rolledBack", ...
                @() obj.applyBoundControl(target, value, false));
        end

        function applyControlValue(obj, target, value)
            obj.recordOperation( ...
                "runtime.interaction", "interaction.value_changed", ...
                "Applying control value.", ...
                "committed", "rolledBack", @apply);

            function apply()
                plan = obj.Contract.PlatformPlan;
                index = find(string({plan.Nodes.Id}) == string(target), 1);
                if isempty(index)
                    error("labkit:app:contract:UnknownReference", ...
                        "Layout target is undeclared: %s.", target);
                end
                configuration = plan.Nodes(index).Configuration;
                directManipulation = plan.Nodes(index).Kind == "slider";
                if isfield(configuration, "Bind") && ...
                        strlength(configuration.Bind) > 0
                    obj.applyBoundControl( ...
                        target, value, true, ~directManipulation);
                else
                    binding = ...
                        labkit.app.internal.runtime.RuntimeContractBoundary.signalForTarget( ...
                        obj.Contract, target, "valueChanged", false);
                    if isempty(binding)
                        error("labkit:app:contract:UnknownReference", ...
                            "Layout target has no value behavior: %s.", ...
                            target);
                    end
                    if directManipulation
                        obj.enqueueTransition( ...
                            binding, value, @(state) state, ...
                            "Callback " + binding.Id, string(target), ...
                            [], false);
                    else
                        obj.dispatch(binding, value);
                    end
                end
            end
        end

        function invokeAction(obj, target)
            obj.assertOpen();
            binding = ...
                labkit.app.internal.runtime.RuntimeContractBoundary.signalForTarget( ...
                obj.Contract, target, "pressed");
            obj.recordOperation( ...
                "runtime.interaction", "interaction.action_invoked", ...
                "Invoking application action.", ...
                "committed", "rolledBack", ...
                @() obj.dispatch(binding, []));
        end

        function applyTableEdit(obj, target, edit)
            obj.assertOpen();
            if ~isa(edit, "labkit.app.event.TableCellEdit")
                error("labkit:app:contract:InvalidValue", ...
                    "Table edit payload must be a TableEdit value.");
            end
            binding = ...
                labkit.app.internal.runtime.RuntimeContractBoundary.signalForTarget( ...
                obj.Contract, target, "cellEdited");
            obj.recordOperation( ...
                "runtime.interaction", "interaction.table_edited", ...
                "Applying table edit.", ...
                "committed", "rolledBack", ...
                @() obj.dispatch(binding, edit));
        end

        function applyTableSelection(obj, target, cells)
            obj.assertOpen();
            selection = labkit.app.event.TableCellSelection(cells);
            binding = ...
                labkit.app.internal.runtime.RuntimeContractBoundary.signalForTarget( ...
                obj.Contract, target, "cellSelectionChanged");
            obj.recordOperation( ...
                "runtime.interaction", "interaction.table_selected", ...
                "Applying table selection.", ...
                "committed", "rolledBack", ...
                @() obj.dispatch(binding, selection));
        end

        function applyWorkspacePage(obj, target, pageId)
            obj.assertOpen();
            binding = ...
                labkit.app.internal.runtime.RuntimeContractBoundary.signalForTarget( ...
                obj.Contract, target, "pageChanged");
            obj.recordOperation( ...
                "runtime.interaction", "interaction.page_changed", ...
                "Applying workspace page selection.", ...
                "committed", "rolledBack", ...
                @() obj.dispatch(binding, string(pageId)));
        end

        function applyInteraction(obj, interactionId, signal, payload)
            obj.assertOpen();
            binding = ...
                labkit.app.internal.runtime.RuntimeContractBoundary.interactionSignal( ...
                obj.Contract, interactionId, signal);
            obj.recordOperation( ...
                "runtime.interaction", "interaction.managed_committed", ...
                "Applying managed interaction.", ...
                "committed", "rolledBack", ...
                @() obj.enqueueTransition( ...
                    binding, payload, @(state) state, ...
                    "Callback " + binding.Id, string(interactionId), ...
                    [], false));
        end

        function applyFilePanelSelection(obj, target, indices)
            obj.assertOpen();
            [config, current] = ...
                labkit.app.internal.runtime.RuntimeContractBoundary.fileListState( ...
                obj.Contract, obj.State, target);
            obj.recordOperation( ...
                "runtime.source", "source.selection_changed", ...
                "Applying source selection.", ...
                "committed", "rolledBack", ...
                @() obj.commitFilePanel( ...
                    target, config, current, indices, false));
        end

        applyBoundControl(obj, target, value, dispatchChanged, showBusy)

        applyFileSelection(obj, target, paths, indices)

        function removeFileSelection(obj, target, indices)
            obj.assertOpen();
            operation = obj.Recorder.begin( ...
                "runtime.source", "source.files_removed", ...
                "Removing selected source files.");
            try
            [config, current] = ...
                labkit.app.internal.runtime.RuntimeContractBoundary.fileListState( ...
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
                obj.Recorder.finish( ...
                    operation, "completed", "committed", []);
            catch cause
                obj.Recorder.finish( ...
                    operation, "failed", "rolledBack", cause);
                rethrow(cause);
            end
        end

        function close(obj)
            if obj.Closed
                return;
            end
            operation = obj.Recorder.begin( ...
                "runtime.lifecycle", "runtime.close", ...
                "Closing application runtime.");
            obj.Queue = {};
            obj.Closed = true;
            failures = cell(1, 3);
            failureCount = 0;
            if ~isempty(obj.PostedEvents)
                try
                    obj.PostedEvents.close();
                catch cause
                    failureCount = failureCount + 1;
                    failures{failureCount} = cause;
                end
            end
            if ~isempty(obj.Resources)
                try
                    obj.Resources.clearAll();
                catch cause
                    failureCount = failureCount + 1;
                    failures{failureCount} = cause;
                end
            end
            if ~isempty(obj.Adapter) && isvalid(obj.Adapter)
                try
                    obj.Adapter.close();
                catch cause
                    failureCount = failureCount + 1;
                    failures{failureCount} = cause;
                end
            end
            failure = combinedCloseFailure( ...
                failures(1:failureCount));
            if isempty(failure)
                obj.Recorder.finish( ...
                    operation, "completed", "notApplicable", []);
            else
                obj.Recorder.finish( ...
                    operation, "failed", "notApplicable", failure);
            end
            if ~isempty(obj.Diagnostics)
                obj.Diagnostics.exportAfterErrorOnClose(obj.State);
            end
            if ~isempty(obj.Recorder)
                obj.Recorder.close();
            end
            if ~isempty(failure)
                throwAsCaller(failure);
            end
        end

        function delete(obj)
            obj.close();
        end
    end

    methods (Access = private)
        function folder = uniqueSyntheticInputFolder(obj, parent)
            timestamp = string(datetime("now", ...
                "TimeZone", "UTC", "Format", "yyyyMMdd-HHmmss"));
            nonce = extractBefore( ...
                labkit.app.internal.identity.newId(), 9);
            folder = string(fullfile(char(parent), ...
                "labkit-synthetic-" + obj.Application.AppId + "-" + ...
                timestamp + "-" + nonce));
        end

        commitFilePanel(obj, target, config, sources, indices, rebuildSession)

        backend = completeBackend(obj, backend)

        execute(obj, binding, payload, prepareState, failureLabel)

        enqueueTransition(obj, binding, payload, prepareState, ...
            failureLabel, busyMessage, failureHandler, showBusy)

        view = present(obj, state)

        function paths = presentationSourcePaths(obj, records, role)
            records = obj.Sources.recordsForRole(records, role);
            paths = obj.Sources.sourcePaths(records);
        end

        function log(obj, severity, eventName, message, category, audience, attributes, exception)
            obj.Recorder.log(severity, eventName, message, ...
                Category=category, Audience=audience, Attributes=attributes, ...
                Exception=exception);
            if audience == "user" && ...
                    any(severity == ["info", "warning", "error", "critical"])
                obj.CurrentStatus = message;
                if obj.Processing && ...
                        isa(obj.Adapter, ...
                        "labkit.app.internal.native.MatlabPlatformAdapter")
                    obj.Adapter.updateBusy(message);
                end
            end
        end

        function dispatchPostedEvent(obj, eventId, updateState)
            if obj.Closed
                return;
            end
            if obj.Processing
                % A timer or stream can fire while a native presentation
                % yields to MATLAB's event loop. Retain the coalesced event
                % with its pump suspended instead of extending the active
                % transaction with a producer-driven transition chain.
                obj.PostedEvents.defer(eventId, updateState);
                return;
            end
            try
                obj.enqueueTransition( ...
                    [], [], @(state) updateState(state, obj.Context), ...
                    "Posted event " + eventId, "Updating...", ...
                    @(cause) obj.logPostedEventFailure(eventId, cause), false);
            catch cause
                obj.logPostedEventFailure(eventId, cause);
            end
        end

        function logPostedEventFailure(obj, eventId, cause)
            obj.log("error", "callback.posted_failed", ...
                "Posted application event failed.", ...
                "runtime.callback", "developer", ...
                struct("runtimeAlias", eventId), cause);
        end

        backend = wrapDialogOperations(obj, backend)

        function invokeDialogAlert(obj, operation, message, title)
            obj.recordOperation( ...
                "runtime.dialog", "dialog.alert_shown", ...
                "Showing application alert.", ...
                "notApplicable", "notApplicable", ...
                @() operation(message, title));
        end

        function result = invokeDialogChoice( ...
                obj, eventName, message, operation, varargin)
            result = obj.recordOperation( ...
                "runtime.dialog", eventName, message, ...
                "notApplicable", "notApplicable", ...
                @() operation(varargin{:}));
        end

        function varargout = recordOperation( ...
                obj, category, eventName, message, ...
                successDisposition, failureDisposition, operation)
            scope = obj.Recorder.begin(category, eventName, message);
            try
                if nargout == 0
                    operation();
                else
                    [varargout{1:nargout}] = operation();
                end
                obj.Recorder.finish( ...
                    scope, "completed", successDisposition, []);
            catch cause
                obj.Recorder.finish( ...
                    scope, "failed", failureDisposition, cause);
                rethrow(cause);
            end
        end

        function finishProcessing(obj, showBusy)
            obj.Processing = false;
            obj.PostedEvents.resume();
            if showBusy && ...
                    isa(obj.Adapter, "labkit.app.internal.native.MatlabPlatformAdapter")
                obj.Adapter.endBusy(obj.Presentation);
            end
        end

        function updateStartup(obj, message)
            if isa(obj.Adapter, "labkit.app.internal.native.MatlabPlatformAdapter")
                obj.Adapter.startupUpdate(message);
            end
        end

        function notifyUser(obj, message, title)
            if isa(obj.Adapter, ...
                    "labkit.app.internal.native.MatlabPlatformAdapter")
                obj.Adapter.alert(message, title, "info");
            else
                obj.Context.inform(message, title);
            end
        end

        function refreshWindowTitle(obj)
            if isa(obj.Adapter, "labkit.app.internal.native.MatlabPlatformAdapter")
                obj.Adapter.setWindowTitle(obj.formattedWindowTitle());
            end
        end

        function title = formattedWindowTitle(obj)
            title = obj.Application.Title + " v" + ...
                obj.Application.AppVersion + " (" + ...
                obj.Application.Updated + ")";
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

    end
end

function failure = combinedCloseFailure(failures)
if isempty(failures)
    failure = [];
    return;
end
if isscalar(failures)
    failure = failures{1};
    return;
end
failure = MException( ...
    "labkit:app:runtime:CloseFailed", ...
    "Multiple runtime resources failed during close.");
for index = 1:numel(failures)
    failure = addCause(failure, failures{index});
end
end
