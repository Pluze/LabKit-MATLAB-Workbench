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
        Documents
        Sources
        Recorder
        PendingDocumentMetadata = []
    end

    methods (Access = ?labkit.app.internal.RuntimeFactory)
        function obj = RuntimeKernel( ...
                application, contract, initialProject, backend, platform, ...
                recorder)
            obj.Application = application;
            obj.Contract = contract;
            if ~isa(recorder, "labkit.app.internal.SessionDiagnostics") || ...
                    ~isscalar(recorder)
                error("labkit:app:runtime:InvariantFailure", ...
                    "RuntimeKernel requires one SessionDiagnostics service.");
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
                if ~isempty(application.OnStart)
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

        function failNextCommit(obj)
            obj.Adapter.failNextCommit();
        end

        function count = commitCount(obj)
            count = obj.Adapter.CommitCount;
        end

        function events = diagnosticEvents(obj)
            events = obj.Recorder.events();
        end

        function snapshot = diagnosticSnapshot(obj)
            snapshot = obj.Recorder.captureSnapshot();
        end

        function title = sessionLogTitle(obj)
            title = obj.Application.DisplayName + " — Session Log";
        end

        function token = subscribeDiagnostics(obj, callback)
            token = obj.Recorder.subscribe(callback);
        end

        function unsubscribeDiagnostics(obj, token)
            obj.Recorder.unsubscribe(token);
        end

        function setTraceCapture(obj, enabled)
            obj.Recorder.setTraceEnabled(enabled);
        end

        function destination = exportDiagnosticBundle(obj, destination)
            operation = obj.Recorder.begin( ...
                "runtime.lifecycle", "diagnostics.bundle_exported", ...
                "Exporting diagnostic bundle.");
            try
                destination = obj.Recorder.exportBundle( ...
                    destination, operation.Id);
                obj.Recorder.finish( ...
                    operation, "completed", "notApplicable", []);
            catch cause
                obj.Recorder.finish( ...
                    operation, "failed", "notApplicable", cause);
                destination = obj.exportDiagnosticTextFallback( ...
                    destination, cause);
            end
        end

        function destination = exportDiagnosticBundleInteractive(obj)
            destination = "";
            try
                automaticDestination = ...
                    obj.automaticDiagnosticDestination();
                destination = obj.exportDiagnosticBundle( ...
                    automaticDestination);
                if endsWith(destination, ".txt", ...
                        IgnoreCase=true)
                    obj.alertDiagnosticTextFallback(destination);
                else
                    obj.Context.alert( ...
                        "Diagnostic bundle written to:" + newline + ...
                        string(destination), ...
                        "Diagnostic Bundle Exported");
                end
                return;
            catch automaticFailure
                fallbackName = diagnosticFallbackName( ...
                    obj.automaticDiagnosticFilename());
            end
            choice = obj.Context.chooseOutputFile( ...
                {"*.txt", "Diagnostic text fallback (*.txt)"}, ...
                fallbackName);
            if choice.Cancelled
                return;
            end
            destination = obj.exportDiagnosticTextFallback( ...
                choice.Value, automaticFailure);
            obj.alertDiagnosticTextFallback(destination);
        end

        function destination = exportDiagnosticTextFallback( ...
                obj, preferredDestination, cause)
            obj.Recorder.log( ...
                "warning", "diagnostics.text_fallback.started", ...
                "Diagnostic ZIP export failed; writing a plain-text fallback.", ...
                Category="runtime.lifecycle", Audience="user", ...
                Exception=cause);
            destination = obj.Recorder.exportTextFallback( ...
                preferredDestination, cause);
        end

        function alertDiagnosticTextFallback(obj, destination)
            obj.Context.alert( ...
                "The diagnostic ZIP could not be exported. A plain-text " + ...
                "diagnostic fallback was written to:" + newline + ...
                string(destination), ...
                "Diagnostic Text Fallback");
        end

        function supported = supportsSyntheticInputs(obj)
            supported = ~isempty(obj.Application.BuildSyntheticSample);
        end

        function pack = generateSyntheticInputs(obj, folder)
            operation = obj.Recorder.begin( ...
                "runtime.source", "synthetic_inputs.generated", ...
                "Generating synthetic inputs.");
            try
                pack = labkit.app.internal.SyntheticInputGenerator.generate( ...
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
            obj.Context.alert( ...
                "Synthetic inputs were written to the selected folder.", ...
                "Synthetic Inputs");
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
            operation = obj.Recorder.begin( ...
                "runtime.project", "project.saved", ...
                "Saving project document.");
            try
                result = obj.Documents.save(state, filepath);
                obj.refreshWindowTitle();
                obj.Recorder.finish( ...
                    operation, "completed", "committed", []);
            catch cause
                obj.Recorder.finish( ...
                    operation, "failed", "rolledBack", cause);
                rethrow(cause);
            end
        end

        function state = prepareProjectRestore(obj, filepath)
            obj.assertOpen();
            obj.assertProjectStore();
            operation = obj.Recorder.begin( ...
                "runtime.project", "project.restore_prepared", ...
                "Preparing project restore.");
            try
                [state, obj.PendingDocumentMetadata] = ...
                    obj.Documents.restore(filepath, false);
                obj.Recorder.finish( ...
                    operation, "completed", "notApplicable", []);
            catch cause
                obj.Recorder.finish( ...
                    operation, "failed", "notApplicable", cause);
                rethrow(cause);
            end
        end

        function state = prepareNewProject(obj)
            obj.assertOpen();
            obj.assertProjectStore();
            operation = obj.Recorder.begin( ...
                "runtime.project", "project.new_prepared", ...
                "Preparing a new project.");
            try
                [state, obj.PendingDocumentMetadata] = ...
                    obj.Documents.createNew();
                obj.Recorder.finish( ...
                    operation, "completed", "notApplicable", []);
            catch cause
                obj.Recorder.finish( ...
                    operation, "failed", "notApplicable", cause);
                rethrow(cause);
            end
        end

        function saveRecovery(obj, state, filepath)
            obj.assertProjectStore();
            operation = obj.Recorder.begin( ...
                "runtime.project", "project.recovery_saved", ...
                "Saving project recovery document.");
            try
                obj.Documents.saveRecovery(state, filepath);
                obj.Recorder.finish( ...
                    operation, "completed", "committed", []);
            catch cause
                obj.Recorder.finish( ...
                    operation, "failed", "rolledBack", cause);
                rethrow(cause);
            end
        end

        function restoreProject(obj, filepath, asRecovery)
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
                labkit.app.internal.RuntimeContractBoundary.validateState( ...
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
            written = obj.recordOperation( ...
                "runtime.result", "result.written", ...
                "Writing result package.", ...
                "committed", "rolledBack", ...
                @() writer.write(folder, result));
        end

        function record = sourceRecord(obj, id, role, path, required)
            record = obj.recordOperation( ...
                "runtime.source", "source.record_created", ...
                "Creating portable source record.", ...
                "notApplicable", "notApplicable", ...
                @() obj.Sources.create(id, role, path, required));
        end

        function paths = sourcePaths(obj, sources, ids)
            paths = obj.recordOperation( ...
                "runtime.source", "source.paths_resolved", ...
                "Resolving portable source paths.", ...
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
                "Updating portable source records.", ...
                "notApplicable", "notApplicable", ...
                @() obj.Sources.upsert(sources, record));
        end

        function sources = reconcileSources(obj, current, incoming)
            sources = obj.recordOperation( ...
                "runtime.source", "source.records_reconciled", ...
                "Reconciling portable source records.", ...
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
                if isfield(configuration, "Bind") && ...
                        strlength(configuration.Bind) > 0
                    obj.applyBoundControl(target, value, true);
                else
                    binding = ...
                        labkit.app.internal.RuntimeContractBoundary.signalForTarget( ...
                        obj.Contract, target, "valueChanged", false);
                    if isempty(binding)
                        error("labkit:app:contract:UnknownReference", ...
                            "Layout target has no value behavior: %s.", ...
                            target);
                    end
                    obj.dispatch(binding, value);
                end
            end
        end

        function invokeAction(obj, target)
            obj.assertOpen();
            binding = ...
                labkit.app.internal.RuntimeContractBoundary.signalForTarget( ...
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
                labkit.app.internal.RuntimeContractBoundary.signalForTarget( ...
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
                labkit.app.internal.RuntimeContractBoundary.signalForTarget( ...
                obj.Contract, target, "cellSelectionChanged");
            obj.recordOperation( ...
                "runtime.interaction", "interaction.table_selected", ...
                "Applying table selection.", ...
                "committed", "rolledBack", ...
                @() obj.dispatch(binding, selection));
        end

        function applyInteraction(obj, interactionId, signal, payload)
            obj.assertOpen();
            binding = ...
                labkit.app.internal.RuntimeContractBoundary.interactionSignal( ...
                obj.Contract, interactionId, signal);
            obj.recordOperation( ...
                "runtime.interaction", "interaction.managed_committed", ...
                "Applying managed interaction.", ...
                "committed", "rolledBack", ...
                @() obj.dispatch(binding, payload));
        end

        function applyFilePanelSelection(obj, target, indices)
            obj.assertOpen();
            [config, current] = ...
                labkit.app.internal.RuntimeContractBoundary.fileListState( ...
                obj.Contract, obj.State, target);
            obj.recordOperation( ...
                "runtime.source", "source.selection_changed", ...
                "Applying source selection.", ...
                "committed", "rolledBack", ...
                @() obj.commitFilePanel( ...
                    target, config, current, indices, false));
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
            operation = obj.Recorder.begin( ...
                "runtime.source", "source.files_selected", ...
                "Applying selected source files.");
            try
            [config, current] = ...
                labkit.app.internal.RuntimeContractBoundary.fileListState( ...
                obj.Contract, obj.State, target);
            currentRole = obj.Sources.recordsForRole( ...
                current, config.SourceRole);
            currentPaths = obj.Sources.sourcePaths(currentRole);
            [paths, filtering] = ...
                labkit.app.internal.RuntimeContractBoundary.filterFilePaths( ...
                config, paths, currentPaths);
            if filtering.changed
                obj.Recorder.log( ...
                    "info", "source.paths_filtered", ...
                    "Filtered unsupported source files.", ...
                    Category="runtime.source", Audience="user", ...
                    Attributes=struct( ...
                    "acceptedCount", filtering.acceptedCount, ...
                    "rejectedCount", filtering.rejectedCount));
                obj.Context.alert(filtering.message, ...
                    "Unsupported files filtered");
            end
            sources = obj.Sources.reconcileRolePaths( ...
                current, paths, config.SourceRole, ...
                config.SourceIdPrefix, config.Required, ...
                config.AllowDuplicatePaths);
            visibleSources = obj.Sources.recordsForRole( ...
                sources, config.SourceRole);
            if filtering.changed
                indices = 1:numel(visibleSources);
            end
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
                obj.Recorder.finish( ...
                    operation, "completed", "committed", []);
            catch cause
                obj.Recorder.finish( ...
                    operation, "failed", "rolledBack", cause);
                rethrow(cause);
            end
        end

        function removeFileSelection(obj, target, indices)
            obj.assertOpen();
            operation = obj.Recorder.begin( ...
                "runtime.source", "source.files_removed", ...
                "Removing selected source files.");
            try
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
            failures = cell(1, 2);
            failureCount = 0;
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
                string(java.util.UUID.randomUUID()), 9);
            folder = string(fullfile(char(parent), ...
                "labkit-synthetic-" + obj.Application.AppId + "-" + ...
                timestamp + "-" + nonce));
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
            backend = obj.wrapDialogOperations(backend);
        end

        function execute(obj, binding, payload)
            previousState = obj.State;
            previousPresentation = obj.Presentation;
            obj.PendingDocumentMetadata = [];
            operation = obj.Recorder.begin( ...
                "runtime.callback", "callback." + binding.Signal, ...
                "Dispatching callback.", Attributes=struct("runtimeAlias", binding.Id));
            try
                if ~binding.AcceptsPayload
                    candidate = binding.UpdateState(previousState, obj.Context);
                else
                    candidate = binding.UpdateState( ...
                        previousState, payload, obj.Context);
                end
                obj.Recorder.log( ...
                    "trace", "callback.state_updated", ...
                    "Callback state update completed.", ...
                    Category="runtime.callback", Audience="developer", ...
                    Attributes=struct("runtimeAlias", binding.Id));
                labkit.app.internal.RuntimeContractBoundary.validateState( ...
                    obj.Application, candidate);
                obj.Recorder.log( ...
                    "trace", "callback.state_validated", ...
                    "Callback state validation completed.", ...
                    Category="runtime.callback", Audience="developer", ...
                    Attributes=struct("runtimeAlias", binding.Id));
                view = obj.present(candidate);
                obj.Adapter.reconcile(previousPresentation, view);
                obj.Recorder.log( ...
                    "trace", "callback.presentation_committed", ...
                    "Native presentation commit completed.", ...
                    Category="runtime.callback", Audience="developer", ...
                    Attributes=struct("runtimeAlias", binding.Id));
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
                obj.Recorder.log( ...
                    "trace", "callback.rollback_completed", ...
                    "Callback rollback cleanup completed.", ...
                    Category="runtime.callback", Audience="developer", ...
                    Attributes=struct("runtimeAlias", binding.Id));
                failure = MException("labkit:app:runtime:ActionFailed", ...
                    "Callback %s failed transactionally.", binding.Id);
                failure = addCause(failure, cause);
                throwAsCaller(failure);
            end
            obj.PendingDocumentMetadata = [];
            obj.Resources.clearScope("event");
        end

        function view = present(obj, state)
            operation = obj.Recorder.begin( ...
                "runtime.presentation", "presentation.rendered", ...
                "Preparing application presentation.");
            try
                view = labkit.app.internal.RuntimePresentation.fromState( ...
                    obj.Contract.PlatformPlan, state, ...
                    @(records, role) ...
                        obj.presentationSourcePaths(records, role), ...
                    obj.CurrentStatus);
                obj.Recorder.log( ...
                    "trace", "presentation.runtime_prepared", ...
                    "Runtime presentation model prepared.", ...
                    Category="runtime.presentation", Audience="developer");
                if isempty(obj.Application.PresentWorkbench)
                    custom = labkit.app.view.Snapshot();
                else
                    custom = obj.Application.PresentWorkbench(state);
                end
                obj.Recorder.log( ...
                    "trace", "presentation.app_prepared", ...
                    "App presentation overlay prepared.", ...
                    Category="runtime.presentation", Audience="developer");
                view = view.overlayForRuntime(custom);
                obj.Application.validateViewSnapshot(view);
                obj.Recorder.log( ...
                    "trace", "presentation.validated", ...
                    "Combined presentation validated.", ...
                    Category="runtime.presentation", Audience="developer");
                obj.Recorder.finish( ...
                    operation, "completed", "notApplicable", []);
            catch cause
                obj.Recorder.finish( ...
                    operation, "failed", "notApplicable", cause);
                rethrow(cause);
            end
        end

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
            end
        end

        function backend = wrapDialogOperations(obj, backend)
            if isfield(backend, "alert")
                operation = backend.alert;
                backend.alert = @(message, title) ...
                    obj.invokeDialogAlert(operation, message, title);
            end
            if isfield(backend, "choose")
                operation = backend.choose;
                backend.choose = @(prompt, choices, title, ...
                    defaultChoice, cancelChoice) ...
                    obj.invokeDialogChoice( ...
                    "dialog.option_chosen", "Showing option dialog.", ...
                    operation, prompt, choices, title, ...
                    defaultChoice, cancelChoice);
            end
            if isfield(backend, "chooseInputFile")
                operation = backend.chooseInputFile;
                backend.chooseInputFile = @(filters, startPath) ...
                    obj.invokeDialogChoice( ...
                    "dialog.input_file_chosen", ...
                    "Showing input-file dialog.", ...
                    operation, filters, startPath);
            end
            if isfield(backend, "chooseInputFolder")
                operation = backend.chooseInputFolder;
                backend.chooseInputFolder = @(startPath) ...
                    obj.invokeDialogChoice( ...
                    "dialog.input_folder_chosen", ...
                    "Showing input-folder dialog.", ...
                    operation, startPath);
            end
            if isfield(backend, "chooseOutputFile")
                operation = backend.chooseOutputFile;
                backend.chooseOutputFile = @(filters, startPath) ...
                    obj.invokeDialogChoice( ...
                    "dialog.output_file_chosen", ...
                    "Showing output-file dialog.", ...
                    operation, filters, startPath);
            end
            if isfield(backend, "chooseOutputFolder")
                operation = backend.chooseOutputFolder;
                backend.chooseOutputFolder = @(startPath) ...
                    obj.invokeDialogChoice( ...
                    "dialog.output_folder_chosen", ...
                    "Showing output-folder dialog.", ...
                    operation, startPath);
            end
        end

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

        function destination = automaticDiagnosticDestination(obj)
            folder = diagnosticArtifactsFolder();
            if exist(char(folder), "dir") ~= 7
                [created, message] = mkdir(char(folder));
                if ~created
                    error("labkit:app:runtime:DiagnosticWriteFailed", ...
                        "Could not create the diagnostic artifacts folder: %s", ...
                        message);
                end
            end
            destination = fullfile( ...
                folder, obj.automaticDiagnosticFilename());
        end

        function filename = automaticDiagnosticFilename(obj)
            appId = regexprep(lower(obj.Application.AppId), ...
                "[^a-z0-9]+", "-");
            appId = regexprep(appId, "(^-+|-+$)", "");
            timestamp = string(datetime("now", TimeZone="UTC", ...
                Format="yyyyMMdd-HHmmss"));
            nonce = extractBefore( ...
                string(java.util.UUID.randomUUID()), 9);
            filename = "labkit-diagnostics-" + appId + "-" + ...
                timestamp + "-" + nonce + ".zip";
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

function folder = diagnosticArtifactsFolder()
folder = string(fileparts(mfilename("fullpath")));
for index = 1:3
    folder = string(fileparts(folder));
end
folder = fullfile(folder, "artifacts", "diagnostics");
end

function filename = diagnosticFallbackName(zipFilename)
[~, name] = fileparts(string(zipFilename));
filename = name + "-fallback.txt";
end
