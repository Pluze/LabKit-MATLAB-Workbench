classdef AppSdkSpec < matlab.unittest.TestCase
    %APPSDKSPEC Specify the low-boilerplate public App SDK contract.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function compilesDirectSemanticLayoutCallbacks(testCase)
            layout = labkit.app.layout.workbench({ ...
                labkit.app.layout.button("run", "Run", @runProbe, ...
                    Tooltip="Run the probe."), ...
                labkit.app.layout.field("gain", Kind="numeric", ...
                    Bind="project.parameters.gain")});
            app = AppSdkSpec.definition(layout, "ProjectSchema", ...
                labkit.app.project.Schema( ...
                Version=1, Create=@createProject, Validate=@validateProject));
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            journal = labkittest.temporarySessionJournal(app, root);
            runtime = labkit.app.internal.runtime.RuntimeFactory.createHeadless( ...
                app, [], struct(), journal);
            cleanup = onCleanup(@() runtime.close());

            runtime.applyBinding("gain", 3);

            testCase.verifyEqual(runtime.State.project.parameters.gain, 3);
            testCase.verifyEqual(labkit.app.internal.contract.DefinitionInspector.signalIds(app), ...
                "run__pressed");
            testCase.verifyFalse(isprop(app, "TargetIds"));
            clear cleanup
        end

        function validatesDefinitionMetadataAndCallbackRoles(testCase)
            layout = labkit.app.layout.workbench({});
            app = AppSdkSpec.definition(layout, "OnStart", @startProbe, ...
                "CreateSession", @createSession, "PresentWorkbench", @presentProbe, ...
                "BuildSyntheticSample", @syntheticSample);

            testCase.verifyEqual(app.launch("version").version, "1.0.0");
            testCase.verifyEqual(string(func2str(app.OnStart)), "startProbe");
            testCase.verifyError(@() AppSdkSpec.invalidAppId(layout), ...
                "labkit:app:contract:InvalidValue");
            testCase.verifyError(@() AppSdkSpec.definition(layout, ...
                "CreateSession", @wrongSession), "labkit:app:contract:CallbackRoleMismatch");
        end

        function exposesTypedEventsRatherThanAmbiguousTransport(testCase)
            edit = labkit.app.event.TableCellEdit( ...
                RowId="row-a", RowIndex=1, ColumnId="group", ColumnIndex=2, ...
                PreviousValue="A", NewValue="B", Data={"row-a", "B"});
            selection = labkit.app.event.ListSelection( ...
                Ids=["row-a", "row-c"], Indices=[1, 3]);
            cells = labkit.app.event.TableCellSelection([1, 2; 3, 1]);

            testCase.verifyEqual(edit.NewValue, "B");
            testCase.verifyEqual(selection.Indices, [1, 3]);
            testCase.verifyEqual(cells.CellIndices, [1, 2; 3, 1]);
            testCase.verifyError(@() labkit.app.event.ListSelection( ...
                Ids=["a", "b"], Indices=1), "labkit:app:contract:InvalidValue");
            testCase.verifyError(@() labkit.app.event.TableCellSelection([1, 1; 1, 1]), ...
                "labkit:app:contract:InvalidValue");
        end

        function callbackContextHasOnlyNamedRuntimeCapabilities(testCase)
            context = labkit.app.internal.runtime.CallbackContextFactory.disconnected();

            testCase.verifyTrue(meta.class.fromName( ...
                "labkit.app.CallbackContext").Sealed);
            testCase.verifyFalse(any(string(properties(context)) == "Backend"));
            testCase.verifyError(@() context.alert("message", "title"), ...
                "labkit:app:runtime:InvariantFailure");
            testCase.verifyError(@() context.inform("message", "title"), ...
                "labkit:app:runtime:InvariantFailure");
        end

        function preservesBothDualYAxisViewports(testCase)
            figureHandle = figure("Visible", "off");
            cleanup = onCleanup(@() close(figureHandle));
            ax = axes(figureHandle);
            yyaxis(ax, "left");
            ylim(ax, [-2, 8]);
            yyaxis(ax, "right");
            ylim(ax, [10, 30]);
            viewport = labkit.app.internal.native.NativeAdapterValues. ...
                captureViewport(ax);

            yyaxis(ax, "left");
            ylim(ax, [0, 1]);
            yyaxis(ax, "right");
            ylim(ax, [0, 1]);
            labkit.app.internal.native.NativeAdapterValues. ...
                restoreViewport(ax, viewport);

            testCase.verifyEqual(ax.YAxis(1).Limits, [-2, 8]);
            testCase.verifyEqual(ax.YAxis(2).Limits, [10, 30]);
            clear cleanup
        end

        function validatesPostedEventCapability(testCase)
            observed = containers.Map("KeyType", "char", "ValueType", "any");
            backend = struct("postEvent", @(eventId, updateState) ...
                capturePostedEvent(observed, eventId, updateState));
            context = ...
                labkit.app.internal.runtime.CallbackContextFactory.create(backend);

            context.postEvent("stream.refresh", @latestStreamRefresh);

            testCase.verifyEqual(observed("eventId"), "stream.refresh");
            testCase.verifyEqual(string(func2str(observed("updateState"))), ...
                "latestStreamRefresh");
            testCase.verifyError(@() context.postEvent("bad event", ...
                @latestStreamRefresh), "labkit:app:contract:InvalidValue");
            testCase.verifyError(@() context.postEvent("stream.refresh", ...
                @invalidPostedUpdate), "labkit:app:contract:InvalidValue");
        end

        function coalescesPostedEventsAndIgnoresThemAfterClose(testCase)
            layout = labkit.app.layout.workbench({ ...
                labkit.app.layout.button("post", "Post", @postStreamRefresh, ...
                    Tooltip="Post synthetic stream refreshes.")});
            app = AppSdkSpec.definition(layout, ...
                "CreateSession", @createPostedEventSession);
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            journal = labkittest.temporarySessionJournal(app, root);
            runtime = labkit.app.internal.runtime.RuntimeFactory.createHeadless( ...
                app, [], struct(), journal);
            cleanup = onCleanup(@() closePostedEventRuntime(runtime));

            runtime.invokeAction("post");
            pause(0.05);
            drawnow;

            testCase.verifyEqual(runtime.State.session.refreshValue, 2);
            testCase.verifyEqual(runtime.State.session.dashboardCount, 1);
            testCase.verifyEqual(runtime.State.session.failedCount, 0);
            context = getappdata(groot, "labkitPostedEventContext");
            runtime.close();
            context.postEvent("stream.refresh", @latestStreamRefresh);
            pause(0.02);
            testCase.verifyTrue(runtime.Closed);
            clear cleanup
        end

        function defersPostedEventsUntilTheActiveTransactionCompletes(testCase)
            layout = labkit.app.layout.workbench({ ...
                labkit.app.layout.button("post", "Post", ...
                    @postFromActiveTransaction, ...
                    Tooltip="Post while the synthetic action remains active.")});
            app = AppSdkSpec.definition(layout, ...
                "CreateSession", @createPostedEventSession);
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            journal = labkittest.temporarySessionJournal(app, root);
            runtime = labkit.app.internal.runtime.RuntimeFactory.createHeadless( ...
                app, [], struct(), journal);
            cleanup = onCleanup(@() closePostedEventRuntime(runtime));

            started = tic;
            runtime.invokeAction("post");
            actionSeconds = toc(started);

            testCase.verifyLessThan(actionSeconds, 0.5, ...
                "A background producer must not extend its active user transaction.");
            pause(0.08);
            drawnow;
            testCase.verifyEqual(runtime.State.session.refreshValue, 2);
            clear cleanup
        end

        function sessionOnlyTransactionsDoNotDirtyProjects(testCase)
            layout = labkit.app.layout.workbench({ ...
                labkit.app.layout.button("session", "Session", ...
                    @changeSessionOnly, Tooltip="Change transient state."), ...
                labkit.app.layout.button("project", "Project", ...
                    @changeProject, Tooltip="Change durable state.")});
            app = AppSdkSpec.definition(layout, ...
                "ProjectSchema", labkit.app.project.Schema( ...
                Version=1, Create=@createProject, Validate=@validateProject), ...
                "CreateSession", @createDirtyTrackingSession);
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            journal = labkittest.temporarySessionJournal(app, root);
            runtime = labkit.app.internal.runtime.RuntimeFactory.createHeadless( ...
                app, [], struct(), journal);
            cleanup = onCleanup(@() runtime.close());
            projectFile = fullfile(root, "project.mat");
            runtime.saveProject(runtime.State, projectFile);

            runtime.invokeAction("session");

            testCase.verifyEqual(runtime.State.session.refreshCount, 1);
            testCase.verifyFalse(runtime.documentMetadata().dirty);

            runtime.invokeAction("project");

            testCase.verifyTrue(runtime.documentMetadata().dirty);
            clear cleanup
        end

        function separatesInformationalAndErrorDialogs(testCase)
            observed = containers.Map("KeyType", "char", "ValueType", "any");
            backend = struct( ...
                "inform", @(message, title) captureDialog( ...
                    observed, "info", message, title), ...
                "alert", @(message, title) captureDialog( ...
                    observed, "error", message, title));
            context = ...
                labkit.app.internal.runtime.CallbackContextFactory.create(backend);

            context.inform("Export completed.", "Exported");
            testCase.verifyEqual(observed("kind"), "info");
            testCase.verifyEqual(observed("message"), "Export completed.");
            testCase.verifyEqual(observed("title"), "Exported");

            context.alert("Export failed.", "Export error");
            testCase.verifyEqual(observed("kind"), "error");
        end

        function nativeDialogFiltersUseMatlabCharacterCells(testCase)
            filters = labkit.app.internal.native.NativeAdapterValues.dialogFilters( ...
                {"*.zip", "Diagnostic bundle (*.zip)"});
            scalarFilter = ...
                labkit.app.internal.native.NativeAdapterValues.dialogFilters("*.png");
            characterFilter = ...
                labkit.app.internal.native.NativeAdapterValues.dialogFilters('*.tif');

            testCase.verifySize(filters, [1, 2]);
            testCase.verifyTrue(all(cellfun(@ischar, filters)));
            testCase.verifyEqual(filters, ...
                {'*.zip', 'Diagnostic bundle (*.zip)'});
            testCase.verifyEqual(scalarFilter, {'*.png'});
            testCase.verifyEqual(characterFilter, {'*.tif'});
        end

        function nativeFileValuesPreserveScalarPathsAndCancellation(testCase)
            windowsPath = char("C" + ":" + "\" + ...
                "synthetic" + "\" + "sample.png");
            labels = labkit.app.internal.native.NativeAdapterValues.formatFileLabels( ...
                windowsPath, 'ready');
            fileCancellation = ...
                labkit.app.internal.native.NativeAdapterValues.dialogPath(0, 0);
            folderCancellation = ...
                labkit.app.internal.native.NativeAdapterValues.folderDialogPath(0);

            testCase.verifySize(labels, [1, 1]);
            testCase.verifySubstring(labels, "[ready]");
            testCase.verifyTrue(fileCancellation.Cancelled);
            testCase.verifyTrue(folderCancellation.Cancelled);
        end

        function nativeDialogsRememberLastSuccessfulInputAndOutputFolders(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            inputFolder = fullfile(root, "input");
            outputFolder = fullfile(root, "output");
            mkdir(inputFolder);
            mkdir(outputFolder);
            inputMemory = capturePreference("LastInputFolder");
            outputMemory = capturePreference("LastOutputFolder");
            cleanup = onCleanup(@() restoreDialogPreferences( ...
                inputMemory, outputMemory));

            labkit.app.internal.native.NativeAdapterValues.rememberDialogFolder( ...
                "input", inputFolder);
            labkit.app.internal.native.NativeAdapterValues.rememberDialogFolder( ...
                "output", outputFolder);

            testCase.verifyEqual(string( ...
                labkit.app.internal.native.NativeAdapterValues.dialogStartFolder( ...
                "input", "")), string(inputFolder));
            testCase.verifyEqual(string( ...
                labkit.app.internal.native.NativeAdapterValues.dialogStartFolder( ...
                "output", "")), string(outputFolder));
            testCase.verifyEqual(string( ...
                labkit.app.internal.native.NativeAdapterValues.dialogStartFolder( ...
                "input", outputFolder)), string(outputFolder), ...
                "An explicit valid start folder must override remembered state.");
            labkit.app.internal.native.NativeAdapterValues.rememberDialogFolder( ...
                "input", fullfile(root, "missing"));
            testCase.verifyEqual(string( ...
                labkit.app.internal.native.NativeAdapterValues.dialogStartFolder( ...
                "input", "")), string(inputFolder), ...
                "An invalid or cancelled choice must preserve remembered state.");
            clear cleanup
        end

        function sourceResolutionTreatsCharacterIdAsOneIdentifier(testCase)
            backend = struct("sourcePaths", @sourcePathsProbe);
            context = labkit.app.internal.runtime.CallbackContextFactory.create(backend);

            paths = context.resolveSourcePaths(struct(), 'source-1');

            testCase.verifyEqual(paths, "resolved-source-1");
        end

        function sourceSelectionNormalizesSupportedPathShapes(testCase)
            layout = labkit.app.layout.workbench({ ...
                labkit.app.layout.fileList("files", ...
                    Bind="project.inputs.sources", ...
                    AllowDuplicatePaths=true)});
            app = AppSdkSpec.definition(layout, "ProjectSchema", ...
                labkit.app.project.Schema( ...
                    Version=1, Create=@createSourceProject, ...
                    Validate=@validateSourceProject));
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            journal = labkittest.temporarySessionJournal(app, root);
            runtime = labkit.app.internal.runtime.RuntimeFactory.createHeadless( ...
                app, [], struct(), journal);
            cleanup = onCleanup(@() runtime.close());
            unicodePath = fullfile(root, 'α-image.png');

            runtime.applyFileSelection("files", unicodePath, 1);
            testCase.verifyNumElements( ...
                runtime.State.project.inputs.sources, 1);
            testCase.verifyEqual( ...
                runtime.State.project.inputs.sources.reference.originalPath, ...
                string(unicodePath));

            drivePath = char("C" + ":" + "\" + ...
                "synthetic" + "\" + "first.png");
            uncPath = char("\" + "\" + "host" + "\" + ...
                "share" + "\" + "second.png");
            paths = {drivePath; uncPath};
            runtime.applyFileSelection("files", paths, [1 2]);
            sources = runtime.State.project.inputs.sources;
            testCase.verifySize(sources, [2, 1]);
            testCase.verifyEqual( ...
                string(arrayfun(@(source) ...
                    source.reference.originalPath, sources)), ...
                string(paths));

            stringPaths = ["first.png", "second.png"];
            runtime.applyFileSelection("files", stringPaths, [1 2]);
            sources = runtime.State.project.inputs.sources;
            testCase.verifySize(sources, [2, 1]);

            runtime.applyFileSelection("files", {unicodePath, unicodePath}, [1 2]);
            sources = runtime.State.project.inputs.sources;
            testCase.verifySize(sources, [2, 1]);
            testCase.verifyEqual( ...
                string(arrayfun(@(source) ...
                    source.reference.originalPath, sources)), ...
                repmat(string(unicodePath), 2, 1));

            runtime.applyFileSelection("files", '', zeros(1, 0));
            testCase.verifyEmpty(runtime.State.project.inputs.sources);
            clear cleanup
        end

        function sourcePathFilterKeepsMatchesAndReportsAggregateCounts(testCase)
            layout = labkit.app.layout.workbench({ ...
                labkit.app.layout.fileList("files", ...
                    Bind="project.inputs.sources", ...
                    PathFilter=@acceptPngPaths, ...
                    PathFilterDescription="PNG image")});
            app = AppSdkSpec.definition(layout, "ProjectSchema", ...
                labkit.app.project.Schema( ...
                    Version=1, Create=@createSourceProject, ...
                    Validate=@validateSourceProject));
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            notices = containers.Map("KeyType", "char", "ValueType", "any");
            backend = struct("alert", @(message, title) ...
                captureAlert(notices, message, title));
            journal = labkittest.temporarySessionJournal(app, root);
            runtime = labkit.app.internal.runtime.RuntimeFactory.createHeadless( ...
                app, [], backend, journal);
            cleanup = onCleanup(@() runtime.close());

            runtime.applyFileSelection("files", ...
                ["first.png", "notes.txt", "second.PNG"], 1:3);

            sources = runtime.State.project.inputs.sources;
            testCase.verifyEqual(numel(sources), 2);
            testCase.verifyEqual(string(arrayfun(@(source) ...
                source.reference.originalPath, sources)), ...
                ["first.png"; "second.PNG"]);
            testCase.verifyEqual(notices("title"), ...
                "Unsupported files filtered");
            testCase.verifyEqual(notices("message"), ...
                "Kept 2 PNG image file(s) and filtered 1 unsupported file(s).");
            records = runtime.diagnosticEvents();
            filtered = records(find(string({records.eventName}) == ...
                "source.paths_filtered", 1, "last"));
            testCase.verifyEqual(filtered.attributes.acceptedCount, 2);
            testCase.verifyEqual(filtered.attributes.rejectedCount, 1);

            runtime.applyFileSelection("files", ...
                ["first.png", "second.PNG", "readme.md"], 1:3);
            testCase.verifyEqual(numel(runtime.State.project.inputs.sources), 2);
            testCase.verifyEqual(notices("message"), ...
                "No PNG image files matched. Filtered 1 unsupported file(s).");
            clear cleanup
        end

        function rejectsMalformedFilePathFilters(testCase)
            testCase.verifyError(@() labkit.app.layout.fileList("files", ...
                PathFilter=@wrongPathFilter), ...
                "labkit:app:contract:CallbackRoleMismatch");
        end

        function rejectsInteractiveLayoutsWithoutBehaviorOwners(testCase)
            nodes = { ...
                labkit.app.layout.field("field", Kind="numeric"), ...
                labkit.app.layout.rangeField("range"), ...
                labkit.app.layout.slider("slider"), ...
                labkit.app.layout.fileList("files"), ...
                labkit.app.layout.plotArea("plot", @drawNothing, ...
                    ViewModes=["First", "Second"]), ...
                labkit.app.layout.dataTable("table", ...
                    Columns="Value", ColumnEditable=true)};
            for index = 1:numel(nodes)
                node = nodes{index};
                testCase.verifyError(@() AppSdkSpec.definition( ...
                    labkit.app.layout.workbench({node})), ...
                    "labkit:app:contract:InvalidValue");
            end
            workspace = labkit.app.layout.workspace( ...
                OnPageChanged=@recordWorkspacePage);
            testCase.verifyError(@() AppSdkSpec.definition( ...
                labkit.app.layout.workbench({}, Workspace=workspace)), ...
                "labkit:app:contract:InvalidValue");
        end

        function rejectsDynamicallyEditableTableWithoutEditCallback(testCase)
            tableNode = labkit.app.layout.dataTable( ...
                "table", Columns="Value");
            app = AppSdkSpec.definition( ...
                labkit.app.layout.workbench({tableNode}), ...
                "PresentWorkbench", @presentEditableTable);
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            journal = labkittest.temporarySessionJournal(app, root);

            testCase.verifyError(@() ...
                labkit.app.internal.runtime.RuntimeFactory.createHeadless( ...
                app, [], struct(), journal), ...
                "labkit:app:contract:InvalidValue");
        end

        function syntheticInputsAreDeliberateAndDoNotChangeTheRuntime(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            layout = labkit.app.layout.workbench({ ...
                labkit.app.layout.field("gain", Kind="numeric", ...
                    Bind="project.parameters.gain")});
            app = AppSdkSpec.definition(layout, "ProjectSchema", ...
                labkit.app.project.Schema(Version=1, Create=@createProject, ...
                Validate=@validateProject), CreateSession=@sampleSession, ...
                OnStart=@startChangesGain, BuildSyntheticSample=@validSyntheticSample);
            journal = labkittest.temporarySessionJournal(app, folder);
            runtime = labkit.app.internal.runtime.RuntimeFactory.createHeadless( ...
                app, [], struct(), journal);
            cleanup = onCleanup(@() runtime.close());
            stateBeforeGeneration = runtime.State;

            pack = runtime.generateSyntheticInputs(folder);

            testCase.verifyEqual(runtime.State.project.parameters.gain, 99);
            testCase.verifyEqual(runtime.State.session.gainAtCreation, 1);
            testCase.verifyEqual(runtime.State, stateBeforeGeneration);
            testCase.verifyEqual(pack.InitialProject.parameters.gain, 7);
            testCase.verifyTrue(isfile(fullfile( ...
                folder, "synthetic-input-pack.json")));
            clear cleanup

            projectFreeApp = AppSdkSpec.definition( ...
                labkit.app.layout.workbench({}), ...
                BuildSyntheticSample=@projectFreeSyntheticSample);
            projectFreeJournal = labkittest.temporarySessionJournal( ...
                projectFreeApp, folder);
            projectFreeRuntime = ...
                labkit.app.internal.runtime.RuntimeFactory.createHeadless( ...
                projectFreeApp, [], struct(), projectFreeJournal);
            projectFreeCleanup = onCleanup(@() projectFreeRuntime.close());
            stateBeforeGeneration = projectFreeRuntime.State;

            projectFreePack = projectFreeRuntime.generateSyntheticInputs(folder);

            testCase.verifyEqual(projectFreeRuntime.State, ...
                stateBeforeGeneration);
            testCase.verifyEmpty(fieldnames(projectFreePack.InitialProject));
            clear projectFreeCleanup
        end

        function restoresDeclaredMigrationsAndReadOnlyImports(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            layout = labkit.app.layout.workbench({});
            schema = labkit.app.project.Schema( ...
                Version=2, Create=@createCurrentProject, ...
                Validate=@validateCurrentProject, ...
                Migrate=@migrateProbeProject, ...
                LegacyImports=struct("probeLegacy", @importProbeProject));
            app = AppSdkSpec.definition(layout, "ProjectSchema", schema);
            journal = labkittest.temporarySessionJournal(app, folder);
            runtime = labkit.app.internal.runtime.RuntimeFactory.createHeadless( ...
                app, [], struct(), journal);
            cleanup = onCleanup(@() runtime.close());

            oldProjectFile = fullfile(folder, "old-project.mat");
            runtime.saveProject(runtime.State, oldProjectFile);
            loaded = load(oldProjectFile, "labkitProject");
            labkitProject = loaded.labkitProject;
            labkitProject.app.payloadVersion = 1;
            labkitProject.payload.parameters = ...
                rmfield(labkitProject.payload.parameters, "unit");
            save(oldProjectFile, "labkitProject");

            runtime.restoreProject(oldProjectFile);
            testCase.verifyEqual(runtime.State.project.parameters.unit, "base");

            legacyFile = fullfile(folder, "legacy-project.mat");
            probeLegacy = struct("gain", 7);
            save(legacyFile, "probeLegacy");
            runtime.restoreProject(legacyFile);
            testCase.verifyEqual(runtime.State.project.parameters.gain, 7);
            testCase.verifyEqual(runtime.State.project.parameters.unit, "base");

            labkitProject.app.payloadVersion = 3;
            newerFile = fullfile(folder, "newer-project.mat");
            save(newerFile, "labkitProject");
            testCase.verifyError(@() runtime.restoreProject(newerFile), ...
                "labkit:app:runtime:NewerProjectPayload");
            clear cleanup
        end

        function preventsExternalProjectOverwriteAndAllowsSaveAs(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            layout = labkit.app.layout.workbench({});
            schema = labkit.app.project.Schema(Version=1, ...
                Create=@createProject, Validate=@validateProject);
            app = AppSdkSpec.definition(layout, "ProjectSchema", schema);
            journal = labkittest.temporarySessionJournal(app, folder);
            runtime = labkit.app.internal.runtime.RuntimeFactory.createHeadless( ...
                app, [], struct(), journal);
            cleanup = onCleanup(@() runtime.close());
            original = fullfile(folder, "project.mat");
            alternate = fullfile(folder, "alternate.mat");

            runtime.saveProject(runtime.State, original);
            external = load(original, "labkitProject");
            labkitProject = external.labkitProject;
            labkitProject.payload.parameters.gain = 7;
            save(original, "labkitProject");

            testCase.verifyError( ...
                @() runtime.saveProject(runtime.State, original), ...
                "labkit:app:runtime:ProjectWriteConflict");
            runtime.saveProject(runtime.State, alternate);
            testCase.verifyTrue(isfile(alternate));
            clear cleanup
        end

        function explicitSourceBindingsOverrideDefaultInference(testCase)
            inferred = labkit.app.project.Schema(Version=1, ...
                Create=@createSourceProject, Validate=@validateSourceProject);
            explicit = labkit.app.project.Schema(Version=1, ...
                Create=@createSourceProject, Validate=@validateSourceProject, ...
                SourceBindings="inputs.sources");
            none = labkit.app.project.Schema(Version=1, ...
                Create=@createProject, Validate=@validateProject, ...
                SourceBindings=strings(1, 0));

            testCase.verifyTrue(inferred.UsesInferredSourceBindings);
            testCase.verifyFalse(explicit.UsesInferredSourceBindings);
            testCase.verifyEqual(explicit.SourceBindings, "inputs.sources");
            testCase.verifyFalse(none.UsesInferredSourceBindings);
            testCase.verifyEmpty(none.SourceBindings);
            testCase.verifyError(@() labkit.app.project.Schema( ...
                Version=1, Create=@createProject, Validate=@validateProject, ...
                SourceBindings="project.inputs.sources"), ...
                "labkit:app:contract:InvalidValue");
        end

        function insertsOpenAnchorsByVisiblePathLocation(testCase)
            points = [20 50; 50 50; 80 50];
            imageSize = [100 100];

            for style = ["Straight lines", "Curve"]
                prepended = labkit.app.internal.interaction.addOrInsertAnchor( ...
                    points, [5 60], imageSize, style, false, inf);
                inserted = labkit.app.internal.interaction.addOrInsertAnchor( ...
                    points, [35 90], imageSize, style, false, inf);
                appended = labkit.app.internal.interaction.addOrInsertAnchor( ...
                    points, [95 60], imageSize, style, false, inf);

                testCase.verifyEqual(prepended, [[5 60]; points]);
                testCase.verifyEqual(inserted, ...
                    [points(1, :); 35 90; points(2:3, :)]);
                testCase.verifyEqual(appended, [points; 95 60]);
            end
        end
    end

    methods (Test, TestTags = {'Contract:source', 'Env:hidden-gui'})
        function nativeLayoutUsesConsistentButtonsAndBoundedDividers(testCase)
            controls = { ...
                labkit.app.layout.tab("controls", "Controls", { ...
                    labkit.app.layout.section("first", "First", { ...
                        labkit.app.layout.button("shortAction", ...
                            "Run", @runProbe), ...
                        labkit.app.layout.button("longAction", ...
                            "Measure length + curvature", @runProbe), ...
                        labkit.app.layout.field("summary", ...
                            Kind="readonly", ...
                            Value="Reader-facing status grows naturally as current content wraps across several lines in the available value column, without any App-owned line count, alternate control type, or layout-specific presentation option.")}), ...
                    labkit.app.layout.section("second", "Second", { ...
                        labkit.app.layout.button("exportAction", ...
                            "Export result CSV", @runProbe), ...
                        labkit.app.layout.field("compactSummary", ...
                            Kind="readonly", Value="Ready")})})};
            app = AppSdkSpec.definition( ...
                labkit.app.layout.workbench(controls));
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            journal = labkittest.temporarySessionJournal(app, root);
            runtime = labkit.app.internal.runtime.RuntimeFactory.createMatlab( ...
                app, [], struct(), journal);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();

            short = oneTagged(figureValue, "shortAction");
            long = oneTagged(figureValue, "longAction");
            export = oneTagged(figureValue, "exportAction");
            testCase.verifyEqual(short.Position(4), long.Position(4), ...
                AbsTol=0.5);
            testCase.verifyEqual(short.Position(4), export.Position(4), ...
                AbsTol=0.5);
            testCase.verifyGreaterThanOrEqual(short.Position(4), 22);
            testCase.verifyLessThanOrEqual(short.Position(4), 32);
            if isprop(long, "WordWrap")
                testCase.verifyEqual(string(long.WordWrap), "off");
            end
            testCase.verifyNumElements(findall( ...
                figureValue, "Tag", "labkitAppRowResize"), 1);
            summary = oneTagged(figureValue, "summary");
            compact = oneTagged(figureValue, "compactSummary");
            testCase.verifyClass(summary, "matlab.ui.control.TextArea");
            testCase.verifyClass(compact, "matlab.ui.control.TextArea");
            testCase.verifyEqual(string(compact.Tooltip), "Ready");
            testCase.verifyGreaterThan(summary.Position(4), ...
                compact.Position(4));
            charHeight = labkit.app.internal.native.NativeAdapterValues.readonlyHeight( ...
                'Ready', 210, 12);
            stringHeight = labkit.app.internal.native.NativeAdapterValues.readonlyHeight( ...
                "Ready", 210, 12);
            testCase.verifyEqual(charHeight, stringHeight);
            clear cleanup
        end

        function nativeInputBridgeDispatchesEverySemanticControl(testCase)
            layout = nativeBridgeLayout();
            app = AppSdkSpec.definition(layout, ...
                "CreateSession", @createNativeBridgeSession);
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            journal = labkittest.temporarySessionJournal(app, root);
            runtime = labkit.app.internal.runtime.RuntimeFactory.createMatlab( ...
                app, [], struct(), journal);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();

            field = oneTagged(figureValue, "nativeField");
            field.Value = 2;
            invokeNativeCallback(field.ValueChangedFcn, field, struct());

            rangeStart = oneTagged(figureValue, "nativeRange");
            rangeEnd = oneTagged(figureValue, "nativeRange.end");
            rangeStart.Value = 0.2;
            rangeEnd.Value = 0.8;
            invokeNativeCallback( ...
                rangeEnd.ValueChangedFcn, rangeEnd, struct());

            spinner = oneTagged(figureValue, "nativeSlider");
            slider = oneTagged(figureValue, "nativeSlider.slider");
            spinner.Value = 0.4;
            invokeNativeCallback( ...
                spinner.ValueChangedFcn, spinner, struct());
            invokeNativeCallback( ...
                slider.ValueChangingFcn, slider, struct("Value", 0.6));

            mode = oneTagged(figureValue, "nativePlot.viewMode");
            mode.Value = "Second";
            invokeNativeCallback(mode.ValueChangedFcn, mode, struct());

            tableHandle = oneTagged(figureValue, "nativeTable");
            tableHandle.Data = {2};
            editEvent = struct("Indices", [1 1], ...
                "PreviousData", 1, "NewData", 2, "EditData", 2);
            invokeNativeCallback( ...
                tableHandle.CellEditCallback, tableHandle, editEvent);
            if isprop(tableHandle, "SelectionChangedFcn") && ...
                    ~isempty(tableHandle.SelectionChangedFcn)
                selectionCallback = tableHandle.SelectionChangedFcn;
            else
                selectionCallback = tableHandle.CellSelectionCallback;
            end
            selectionEvent = struct( ...
                "Selection", [1 1], "Indices", [1 1]);
            invokeNativeCallback( ...
                selectionCallback, tableHandle, selectionEvent);

            state = runtime.State.session;
            testCase.verifyEqual(state.fieldValue, 2);
            testCase.verifyEqual(state.rangeValue, [0.2 0.8]);
            testCase.verifyEqual(state.sliderValue, 0.6);
            testCase.verifyEqual(state.plotMode, "Second");
            testCase.verifyEqual(state.editedValue, 2);
            testCase.verifyEqual(state.selectedCells, [1 1]);
            testCase.verifyEqual(string(figureValue.Tag), "labkitApp");
            events = runtime.diagnosticEvents();
            aliases = callbackStartAliases(events);
            testCase.verifyTrue(all(ismember([ ...
                "nativeField__valueChanged", ...
                "nativeRange__valueChanged", ...
                "nativeSlider__valueChanged", ...
                "nativePlot__valueChanged", ...
                "nativeTable__cellEdited", ...
                "nativeTable__cellSelectionChanged"], aliases)));
            clear cleanup
        end

        function workspacePagesWithoutCallbackUseNativeSelectionOnly(testCase)
            workspace = labkit.app.layout.workspace();
            workspace = workspace.page("firstPage", "First", ...
                labkit.app.layout.statusPanel("firstStatus"));
            workspace = workspace.page("secondPage", "Second", ...
                labkit.app.layout.statusPanel("secondStatus"));
            layout = labkit.app.layout.workbench({}, Workspace=workspace);
            app = AppSdkSpec.definition(layout);
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            journal = labkittest.temporarySessionJournal(app, root);
            runtime = labkit.app.internal.runtime.RuntimeFactory.createMatlab( ...
                app, [], struct(), journal);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();
            group = oneTagged(figureValue, "workspace");
            secondPage = oneTagged(figureValue, "secondPage");

            testCase.verifyEmpty(group.SelectionChangedFcn);
            group.SelectedTab = secondPage;
            drawnow;

            testCase.verifyEqual(string(group.SelectedTab.Tag), "secondPage");
            clear cleanup
        end

        function workspacePageCallbackReceivesSelectedPageId(testCase)
            workspace = labkit.app.layout.workspace( ...
                OnPageChanged=@recordWorkspacePage);
            workspace = workspace.page("firstPage", "First", ...
                labkit.app.layout.statusPanel("firstStatus"));
            workspace = workspace.page("secondPage", "Second", ...
                labkit.app.layout.statusPanel("secondStatus"));
            layout = labkit.app.layout.workbench({}, Workspace=workspace);
            app = AppSdkSpec.definition(layout, ...
                "CreateSession", @createWorkspaceSession);
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            journal = labkittest.temporarySessionJournal(app, root);
            runtime = labkit.app.internal.runtime.RuntimeFactory.createMatlab( ...
                app, [], struct(), journal);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();
            group = oneTagged(figureValue, "workspace");
            secondPage = oneTagged(figureValue, "secondPage");

            group.SelectedTab = secondPage;
            group.SelectionChangedFcn(group, []);
            drawnow;

            testCase.verifyEqual( ...
                runtime.State.session.selectedPage, "secondPage");
            clear cleanup
        end

        function updatesAFieldAndItsCachedLabelWithoutTreeDiscovery(testCase)
            layout = labkit.app.layout.workbench({ ...
                labkit.app.layout.field("gain", Kind="numeric", ...
                    Bind="project.parameters.gain")});
            app = AppSdkSpec.definition(layout, "ProjectSchema", ...
                labkit.app.project.Schema( ...
                    Version=1, Create=@createProject, Validate=@validateProject), ...
                "PresentWorkbench", @presentGainAvailability);
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            journal = labkittest.temporarySessionJournal(app, root);
            runtime = labkit.app.internal.runtime.RuntimeFactory.createMatlab( ...
                app, [], struct(), journal);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();
            field = findall(figureValue, "Tag", "gain");
            label = findall(figureValue, "Tag", "gain.label");

            testCase.verifyEqual(string(field.Enable), "on");
            testCase.verifyEmpty(findall(figureValue, ...
                "Tag", "labkitAppUtilitySyntheticInputs"));
            testCase.verifyEqual(string(label.Enable), "on");
            runtime.applyBinding("gain", 0);
            testCase.verifyEqual(string(field.Enable), "off");
            testCase.verifyEqual(string(label.Enable), "off");
            clear cleanup
        end

        function exposesSyntheticInputGenerationAsAnOrdinaryTool(testCase)
            layout = labkit.app.layout.workbench({});
            app = AppSdkSpec.definition(layout, "ProjectSchema", ...
                labkit.app.project.Schema( ...
                Version=1, Create=@createProject, Validate=@validateProject), ...
                "BuildSyntheticSample", @validSyntheticSample);
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            journal = labkittest.temporarySessionJournal(app, root);
            runtime = labkit.app.internal.runtime.RuntimeFactory.createMatlab( ...
                app, [], struct(), journal);
            cleanup = onCleanup(@() runtime.close());

            menu = findall(runtime.figureHandle(), ...
                "Tag", "labkitAppUtilitySyntheticInputs");

            testCase.verifyNumElements(menu, 1);
            testCase.verifyEqual(string(menu.Text), ...
                "Generate Synthetic Inputs...");
            clear cleanup
        end

        function namesScreenshotTargetsAndSavesProjectStateToArtifacts(testCase)
            layout = labkit.app.layout.workbench({ ...
                labkit.app.layout.field("gain", Kind="numeric", ...
                    Bind="project.parameters.gain")});
            app = AppSdkSpec.definition(layout, "ProjectSchema", ...
                labkit.app.project.Schema( ...
                    Version=1, Create=@createProject, ...
                    Validate=@validateProject));
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            journal = labkittest.temporarySessionJournal(app, root);
            runtime = labkit.app.internal.runtime.RuntimeFactory.createMatlab( ...
                app, [], struct(), journal);
            cleanup = onCleanup(@() runtime.close());
            states = sdkArtifactFolder("states");
            beforeStates = artifactFiles( ...
                states, "labkit-state-probe-app-*.mat");
            fileCleanup = onCleanup(@() deleteNewStateArtifacts( ...
                states, beforeStates));
            figureValue = runtime.figureHandle();
            screenshotMenu = oneTagged( ...
                figureValue, "labkitAppUtilityScreenshot");
            stateMenu = oneTagged( ...
                figureValue, "labkitAppUtilitySaveState");

            testCase.verifyEqual(string(screenshotMenu.Text), ...
                "Save to Artifacts");
            testCase.verifyEqual(string(stateMenu.Text), "Save State");
            screenshotTarget = runtime.automaticArtifactDestination( ...
                "screenshots", "screenshot", ".png");
            testCase.verifyTrue(contains(screenshotTarget, ...
                fullfile("artifacts", "screenshots")));
            testCase.verifyTrue(endsWith(screenshotTarget, ".png"));
            invokeMenu(stateMenu);

            afterStates = artifactFiles( ...
                states, "labkit-state-probe-app-*.mat");
            testCase.verifyNumElements( ...
                setdiff(afterStates, beforeStates), 1);
            notice = getappdata(figureValue, "labkitAppLastAlert");
            testCase.verifyEqual(notice.title, "State Saved");
            testCase.verifyEqual(notice.icon, "info");
            clear fileCleanup cleanup
        end

        function filePanelFailuresAlwaysShowAnAlert(testCase)
            layout = labkit.app.layout.workbench({ ...
                labkit.app.layout.fileList("files", ...
                    Bind="project.inputs.sources", ...
                    SelectionMode="single", MaxFiles=1, ...
                    OnSelectionChanged=@failSourceSelection)});
            app = AppSdkSpec.definition(layout, "ProjectSchema", ...
                labkit.app.project.Schema( ...
                    Version=1, Create=@createUnreadableSourceProject, ...
                    Validate=@validateSourceProject));
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            journal = labkittest.temporarySessionJournal(app, root);
            runtime = labkit.app.internal.runtime.RuntimeFactory.createMatlab( ...
                app, [], struct(), journal);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();
            list = oneTagged(figureValue, "files");

            list.ValueChangedFcn(list, []);
            drawnow;

            notice = getappdata(figureValue, "labkitAppLastAlert");
            testCase.verifyEqual(notice.title, "Could not select file");
            testCase.verifyEqual(notice.icon, "error");
            testCase.verifySubstring(notice.message, ...
                "Synthetic source parse failure");
            clear cleanup
        end

        function delaysBusyFeedbackAndBlocksReentrantInput(testCase)
            observed = containers.Map("KeyType", "char", ...
                "ValueType", "any");
            observed("secondaryCount") = 0;
            setappdata(groot, "labkitAppSdkBusyProbe", observed);
            probeCleanup = onCleanup(@() removeBusyProbe());
            layout = labkit.app.layout.workbench({ ...
                labkit.app.layout.field("gain", Kind="numeric", ...
                    Bind="project.parameters.gain"), ...
                labkit.app.layout.button("quick", "Quick", ...
                    @AppSdkSpec.quickBusyProbe, ...
                    Tooltip="Run a short busy-state probe."), ...
                labkit.app.layout.button("slow", "Slow", ...
                    @AppSdkSpec.slowBusyProbe, ...
                    BusyMessage="Initial stage", ...
                    Tooltip="Run a delayed busy-state probe."), ...
                labkit.app.layout.button("secondary", "Secondary", ...
                    @AppSdkSpec.secondaryBusyProbe, ...
                    Tooltip="Record a secondary action invocation.")});
            app = AppSdkSpec.definition(layout, "ProjectSchema", ...
                labkit.app.project.Schema( ...
                    Version=1, Create=@createProject, ...
                    Validate=@validateProject));
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            journal = labkittest.temporarySessionJournal(app, root);
            runtime = labkit.app.internal.runtime.RuntimeFactory.createMatlab( ...
                app, [], struct(), journal);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();
            observed("figure") = figureValue;
            quick = oneTagged(figureValue, "quick");
            slow = oneTagged(figureValue, "slow");
            gain = oneTagged(figureValue, "gain");

            quick.ButtonPushedFcn(quick, []);

            testCase.verifyTrue(observed("quickBusy"));
            testCase.verifyEqual(observed("quickPointer"), "arrow");
            testCase.verifyFalse(contains( ...
                observed("quickTitle"), "[Working:"));
            testCase.verifyEqual(observed("secondaryCount"), 0);
            testCase.verifyEqual(runtime.State.project.parameters.gain, 1);
            testCase.verifyEqual(gain.Value, 1);

            slow.ButtonPushedFcn(slow, []);

            testCase.verifyEqual(observed("slowPointer"), "watch");
            testCase.verifyTrue(contains( ...
                observed("slowTitle"), "Initial stage"));
            testCase.verifyEqual(observed("secondaryEnable"), "off");
            testCase.verifyEqual(observed("secondaryCount"), 0);
            testCase.verifyTrue(contains( ...
                observed("progressTitle"), "Stage two"));
            testCase.verifyEqual(runtime.State.project.parameters.gain, 1);
            testCase.verifyEqual(gain.Value, 1);
            testCase.verifyEqual(string(gain.Enable), "on");
            testCase.verifyEqual(string(figureValue.Pointer), "arrow");
            testCase.verifyFalse(contains( ...
                string(figureValue.Name), "[Working:"));
            testCase.verifyFalse(isappdata(figureValue, "labkitAppBusy"));
            clear probeCleanup cleanup
        end
    end

    methods (Static, Access = private)
        function state = quickBusyProbe(state, ~)
            observed = getappdata(groot, "labkitAppSdkBusyProbe");
            figureValue = observed("figure");
            observed("quickBusy") = ...
                isappdata(figureValue, "labkitAppBusy");
            observed("quickPointer") = string(figureValue.Pointer);
            observed("quickTitle") = string(figureValue.Name);
            secondary = oneTagged(figureValue, "secondary");
            gain = oneTagged(figureValue, "gain");
            secondary.ButtonPushedFcn(secondary, []);
            gain.Value = 7;
            gain.ValueChangedFcn(gain, []);
        end

        function state = slowBusyProbe(state, callbackContext)
            observed = getappdata(groot, "labkitAppSdkBusyProbe");
            pause(0.35);
            drawnow;
            figureValue = observed("figure");
            secondary = oneTagged(figureValue, "secondary");
            gain = oneTagged(figureValue, "gain");
            observed("slowPointer") = string(figureValue.Pointer);
            observed("slowTitle") = string(figureValue.Name);
            observed("secondaryEnable") = string(secondary.Enable);
            secondary.ButtonPushedFcn(secondary, []);
            gain.Value = 9;
            gain.ValueChangedFcn(gain, []);
            callbackContext.log("info", ...
                "probe.busy.stage", "Stage two");
            observed("progressTitle") = string(figureValue.Name);
        end

        function state = secondaryBusyProbe(state, ~)
            observed = getappdata(groot, "labkitAppSdkBusyProbe");
            observed("secondaryCount") = ...
                observed("secondaryCount") + 1;
        end

        function app = definition(layout, varargin)
            app = labkit.app.Definition( ...
                "Entrypoint", "labkit_AppSdkProbe_app", "AppId", "probe.app", ...
                "Title", "SDK probe", "Family", "Tests", "AppVersion", "1.0.0", ...
                "Updated", "2026-07-19", "Requirements", [], "Workbench", layout, ...
                varargin{:});
        end

        function app = invalidAppId(layout)
            app = labkit.app.Definition( ...
                "Entrypoint", "labkit_AppSdkProbe_app", "AppId", "bad identifier", ...
                "Title", "SDK probe", "Family", "Tests", "AppVersion", "1.0.0", ...
                "Updated", "2026-07-19", "Requirements", [], "Workbench", layout);
        end
    end
end

function handle = oneTagged(parent, tag)
handle = findall(parent, "Tag", tag);
assert(isscalar(handle), "Expected one handle tagged " + tag + ".");
end

function invokeMenu(menu)
menu.MenuSelectedFcn(menu, []);
drawnow;
end

function invokeNativeCallback(callback, source, event)
if isa(callback, "function_handle")
    callback(source, event);
else
    callbackFunction = callback{1};
    callbackFunction(source, event, callback{2:end});
end
drawnow;
end

function aliases = callbackStartAliases(events)
aliases = strings(1, 0);
for index = 1:numel(events)
    event = events(index);
    if event.category == "runtime.callback" && ...
            endsWith(event.eventName, ".started") && ...
            isfield(event.attributes, "runtimeAlias")
        aliases(end + 1) = string(event.attributes.runtimeAlias);
    end
end
end

function capturePostedEvent(observed, eventId, updateState)
observed("eventId") = eventId;
observed("updateState") = updateState;
end

function state = invalidPostedUpdate(state)
state = state;
end

function session = createPostedEventSession(~, ~)
session = struct("refreshValue", 0, "dashboardCount", 0, "failedCount", 0);
end

function state = postStreamRefresh(state, callbackContext)
setappdata(groot, "labkitPostedEventContext", callbackContext);
callbackContext.postEvent("stream.refresh", @firstStreamRefresh);
callbackContext.postEvent("stream.refresh", @latestStreamRefresh);
callbackContext.postEvent("dashboard.refresh", @refreshDashboard);
callbackContext.postEvent("failure.refresh", @failPostedRefresh);
end

function state = postFromActiveTransaction(state, callbackContext)
replayTimer = timer("ExecutionMode", "fixedSpacing", "Period", 0.01, ...
    "TasksToExecute", 100, "TimerFcn", @(~, ~) ...
    callbackContext.postEvent("stream.refresh", @latestStreamRefresh));
callbackContext.setResource("application", "postedEventProbe", ...
    replayTimer, @deleteTimer);
start(replayTimer);
pause(0.03);
drawnow;
end

function deleteTimer(value)
if isa(value, "timer") && isvalid(value)
    stop(value);
    delete(value);
end
end

function state = firstStreamRefresh(state, ~)
state.session.refreshValue = 1;
end

function state = latestStreamRefresh(state, ~)
state.session.refreshValue = 2;
end

function state = refreshDashboard(state, ~)
state.session.dashboardCount = state.session.dashboardCount + 1;
end

function state = failPostedRefresh(state, ~)
state.session.failedCount = state.session.failedCount + 1;
error("AppSdkSpec:PostedFailure", "Synthetic posted event failure.");
end

function closePostedEventRuntime(runtime)
if isappdata(groot, "labkitPostedEventContext")
    rmappdata(groot, "labkitPostedEventContext");
end
if ~runtime.Closed
    runtime.close();
end
end

function session = createDirtyTrackingSession(~, ~)
session = struct("refreshCount", 0);
end

function state = changeSessionOnly(state, ~)
state.session.refreshCount = state.session.refreshCount + 1;
end

function state = changeProject(state, ~)
state.project.parameters.gain = state.project.parameters.gain + 1;
end

function folder = sdkArtifactFolder(category)
versionPath = string(which("labkit.app.version"));
root = string(fileparts(fileparts(fileparts(versionPath))));
folder = fullfile(root, "artifacts", category);
end

function files = artifactFiles(folder, pattern)
if ~isfolder(folder)
    files = strings(1, 0);
    return;
end
entries = dir(fullfile(folder, pattern));
files = string({entries.name});
end

function deleteNewStateArtifacts(stateFolder, beforeStates)
deleteArtifactSet(stateFolder, setdiff(artifactFiles( ...
    stateFolder, "labkit-state-probe-app-*.mat"), beforeStates));
end

function deleteArtifactSet(folder, files)
for filename = files
    filepath = fullfile(folder, filename);
    if isfile(filepath)
        delete(filepath);
    end
end
end

function project = createProject()
project = struct("parameters", struct("gain", 1));
end

function project = createSourceProject()
project = struct("inputs", struct( ...
    "sources", labkit.app.project.emptySourceRecords()));
end

function accepted = validateSourceProject(project)
accepted = isstruct(project) && isscalar(project) && ...
    isfield(project, "inputs") && isstruct(project.inputs) && ...
    isfield(project.inputs, "sources") && ...
    isstruct(project.inputs.sources) && iscolumn(project.inputs.sources);
end

function paths = sourcePathsProbe(~, ids)
paths = ("resolved-" + ids(:));
end

function accepted = acceptPngPaths(paths)
accepted = endsWith(lower(paths), ".png");
end

function accepted = wrongPathFilter(~, ~)
accepted = true;
end

function captureAlert(store, message, title)
store("message") = string(message);
store("title") = string(title);
end

function captureDialog(store, kind, message, title)
store("kind") = string(kind);
captureAlert(store, message, title);
end

function accepted = validateProject(project)
accepted = isstruct(project) && isscalar(project) && ...
    isfield(project, "parameters") && isstruct(project.parameters) && ...
    isfield(project.parameters, "gain") && isfinite(project.parameters.gain);
end

function state = runProbe(state, ~)
end

function state = startProbe(state, ~)
end

function removeBusyProbe()
if isappdata(groot, "labkitAppSdkBusyProbe")
    rmappdata(groot, "labkitAppSdkBusyProbe");
end
end

function session = createSession(~, ~)
session = struct();
end

function session = createWorkspaceSession(~, ~)
session = struct("selectedPage", "");
end

function applicationState = recordWorkspacePage( ...
        applicationState, pageId, ~)
applicationState.session.selectedPage = pageId;
end

function view = presentProbe(~)
view = labkit.app.view.Snapshot();
end

function view = presentEditableTable(~)
view = labkit.app.view.Snapshot().tableData( ...
    "table", {1}, Columns="Value", ColumnEditable=true);
end

function layout = nativeBridgeLayout()
controls = { ...
    labkit.app.layout.field("nativeField", Kind="numeric", ...
        Bind="session.fieldValue", OnValueChanged=@recordNativeField), ...
    labkit.app.layout.rangeField("nativeRange", ...
        Bind="session.rangeValue", OnValueChanged=@recordNativeRange), ...
    labkit.app.layout.slider("nativeSlider", ...
        Bind="session.sliderValue", OnValueChanged=@recordNativeSlider), ...
    labkit.app.layout.plotArea("nativePlot", @drawNothing, ...
        ViewModes=["First", "Second"], ...
        OnValueChanged=@recordNativePlotMode), ...
    labkit.app.layout.dataTable("nativeTable", ...
        Columns="Value", ColumnEditable=true, ...
        OnCellEdited=@recordNativeTableEdit, ...
        OnCellSelectionChanged=@recordNativeTableSelection)};
layout = labkit.app.layout.workbench(controls);
end

function session = createNativeBridgeSession(~, ~)
session = struct( ...
    "fieldValue", 0, "rangeValue", [0 1], ...
    "sliderValue", 0, "plotMode", "First", ...
    "editedValue", 0, "selectedCells", zeros(0, 2));
end

function state = recordNativeField(state, value, ~)
state.session.fieldValue = value;
end

function state = recordNativeRange(state, value, ~)
state.session.rangeValue = value;
end

function state = recordNativeSlider(state, value, ~)
state.session.sliderValue = value;
end

function state = recordNativePlotMode(state, value, ~)
state.session.plotMode = value;
end

function state = recordNativeTableEdit(state, edit, ~)
state.session.editedValue = edit.NewValue;
end

function state = recordNativeTableSelection(state, selection, ~)
state.session.selectedCells = selection.CellIndices;
end

function drawNothing(~, ~)
end

function pack = syntheticSample(~)
pack = struct();
end

function session = sampleSession(project, ~)
session = struct("gainAtCreation", project.parameters.gain);
end

function state = startChangesGain(state, ~)
state.project.parameters.gain = 99;
end

function pack = validSyntheticSample(~)
pack = labkit.app.synthetic.Pack( ...
    Scenario="sdk-probe", ...
    InitialProject=struct("parameters", struct("gain", 7)), ...
    Artifacts={});
end

function pack = projectFreeSyntheticSample(~)
pack = labkit.app.synthetic.Pack( ...
    Scenario="project-free-sdk-probe", ...
    InitialProject=struct(), ...
    Artifacts={});
end

function session = wrongSession(~)
session = struct();
end

function view = presentGainAvailability(state)
view = labkit.app.view.Snapshot().enabled( ...
    "gain", state.project.parameters.gain ~= 0);
end

function project = createCurrentProject()
project = struct("parameters", struct("gain", 1, "unit", "base"));
end

function project = createUnreadableSourceProject()
project = createSourceProject();
project.inputs.sources = labkit.app.project.sourceRecord( ...
    "source1", "files", "unreadable.dat", true);
end

function applicationState = failSourceSelection(applicationState, ~, ~)
error("probe:UnreadableSource", "Synthetic source parse failure.");
end

function accepted = validateCurrentProject(project)
accepted = isstruct(project) && isscalar(project) && ...
    isfield(project, "parameters") && ...
    all(isfield(project.parameters, ["gain", "unit"]));
end

function project = migrateProbeProject(project, fromVersion)
if fromVersion ~= 1
    error("probe:UnsupportedProjectMigration", ...
        "Unsupported probe project version.");
end
project.parameters.unit = "base";
end

function project = importProbeProject(legacy)
project = createCurrentProject();
project.parameters.gain = legacy.gain;
end

function memory = capturePreference(name)
memory = struct("name", name, "existed", ispref("LabKit", name), "value", []);
if memory.existed
    memory.value = getpref("LabKit", name);
end
end

function restoreDialogPreferences(inputMemory, outputMemory)
restorePreference(inputMemory);
restorePreference(outputMemory);
end

function restorePreference(memory)
if memory.existed
    setpref("LabKit", memory.name, memory.value);
elseif ispref("LabKit", memory.name)
    rmpref("LabKit", memory.name);
end
end
