classdef AppSdkSpec < matlab.unittest.TestCase
    %APPSDKSPEC Specify the low-boilerplate public App SDK contract.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function compilesDirectSemanticLayoutCallbacks(testCase)
            layout = labkit.app.layout.workbench({ ...
                labkit.app.layout.button("run", "Run", @runProbe, ...
                    Tooltip="Run the probe."), ...
                labkit.app.layout.field("gain", Kind="numeric", ...
                    Bind="project.parameters.gain")});
            app = AppSdkSpec.definition(layout, ...
                "CreateState", @createRuntimeState);
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            journal = labkittest.temporarySessionJournal(app, root);
            runtime = labkit.app.internal.runtime.RuntimeFactory.createHeadless( ...
                app, [], struct(), journal);
            cleanup = onCleanup(@() runtime.close());

            runtime.applyControlValue("gain", 3);

            testCase.verifyEqual(runtime.State.project.parameters.gain, 3);
            testCase.verifyEqual(labkit.app.internal.contract.DefinitionInspector.signalIds(app), ...
                "run__pressed");
            testCase.verifyFalse(isprop(app, "TargetIds"));
            clear cleanup
        end

        function validatesDefinitionMetadataAndCallbackRoles(testCase)
            layout = labkit.app.layout.workbench({});
            app = AppSdkSpec.definition(layout, "OnStart", @startProbe, ...
                "CreateState", @createSessionState, "PresentWorkbench", @presentProbe);

            testCase.verifyEqual(app.launch("version").version, "1.0.0");
            testCase.verifyEqual(string(func2str(app.OnStart)), "startProbe");
            testCase.verifyError(@() AppSdkSpec.invalidAppId(layout), ...
                "labkit:app:contract:InvalidValue");
            testCase.verifyError(@() AppSdkSpec.definition(layout, ...
                "CreateState", @wrongSession), "labkit:app:contract:CallbackRoleMismatch");
        end

        function enforcesFacadeRequirementsBeforeNativeLaunch(testCase)
            app = labkit.app.Definition( ...
                "Entrypoint", "labkit_AppSdkProbe_app", ...
                "AppId", "probe.app", "Title", "SDK probe", ...
                "Family", "Tests", "AppVersion", "1.0.0", ...
                "Updated", "2026-08-17", ...
                "Requirements", labkit.contract.requirements( ...
                "missing_facade", ">=1 <2"), ...
                "Workbench", labkit.app.layout.workbench({}));

            testCase.verifyError(@() app.launch(), ...
                "labkit_AppSdkProbe_app:IncompatibleLabKit");
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

        function rejectsLimitsThatOlderNativeControlsCannotRepresent(testCase)
            testCase.verifyError(@() labkit.app.view.Snapshot().limits( ...
                "frame", [1 1]), "labkit:app:contract:InvalidValue");
            view = labkit.app.view.Snapshot().limits("frame", [1 2]);

            testCase.verifyClass(view, "labkit.app.view.Snapshot");
        end

        function acceptsBoundedSemanticPlotRevisionTokens(testCase)
            view = labkit.app.view.Snapshot().renderPlot( ...
                "plot", struct(), ViewRevision="source:trace-a|x:time");

            testCase.verifyClass(view, "labkit.app.view.Snapshot");
            testCase.verifyError(@() labkit.app.view.Snapshot().renderPlot( ...
                "plot", struct(), ViewRevision=["one", "two"]), ...
                "labkit:app:contract:InvalidValue");
            testCase.verifyError(@() labkit.app.view.Snapshot().renderPlot( ...
                "plot", struct(), ViewRevision=repmat('x', 1, 4097)), ...
                "labkit:app:contract:InvalidValue");
        end

        function pointSlotsDeclareSelectionAndBackgroundGestures(testCase)
            points = labkit.app.interaction.pointSlots("probePoints", ...
                @changeInteractionProbe, ...
                OnSelectionChanged=@changeInteractionProbe, ...
                OnBackgroundPressed=@changeInteractionProbe);
            layout = labkit.app.layout.workbench({ ...
                labkit.app.layout.plotArea("probePlot", @drawNothing, ...
                    Interactions={points})});
            app = AppSdkSpec.definition(layout);

            signals = ...
                labkit.app.internal.contract.DefinitionInspector.signalIds(app);
            testCase.verifyTrue(all(ismember([ ...
                "probePoints__interactionChanged" ...
                "probePoints__selectionChanged" ...
                "probePoints__backgroundPressed"], signals)));
        end

        function pointSlotMarqueeSelectsOnlyEnclosedFinitePoints(testCase)
            points = [4 4; 8 7; 12 9; NaN 6];

            indices = labkit.app.internal.interaction. ...
                selectPointsInRectangle(points, [3 3 5 4]);

            testCase.verifyEqual(indices, [1 2]);
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

        function delegatesCommandWToNativeWindowClose(testCase)
            handlesShortcut = ...
                @labkit.app.internal.native.NativeAdapterValues.handlesCloseShortcut;

            testCase.verifyFalse(handlesShortcut("w", "command"));
            testCase.verifyFalse(handlesShortcut("w", ["control", "command"]));
            testCase.verifyTrue(handlesShortcut("w", "control"));
            testCase.verifyFalse(handlesShortcut("x", "control"));
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
                "CreateState", @createPostedEventSessionState);
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
                "CreateState", @createPostedEventSessionState);
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

        function sourceSelectionNormalizesSupportedPathShapes(testCase)
            layout = labkit.app.layout.workbench({ ...
                labkit.app.layout.fileList("files", ...
                    Bind="project.inputs.sources", ...
                    AllowDuplicatePaths=true)});
            app = AppSdkSpec.definition(layout, ...
                "CreateState", @createSourceState);
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
                runtime.State.project.inputs.sources.path, ...
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
                    source.path, sources)), ...
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
                    source.path, sources)), ...
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
            app = AppSdkSpec.definition(layout, ...
                "CreateState", @createSourceState);
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
                source.path, sources)), ...
                ["first.png"; "second.PNG"]);
            testCase.verifyEqual(notices("title"), ...
                "Unsupported files filtered");
            testCase.verifyEqual(notices("message"), ...
                "Kept 2 PNG image file(s) and filtered 1 unsupported file(s).");
            records = runtime.diagnosticSnapshot().events;
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
        function nativeReconciliationSkipsUnchangedPlotModels(testCase)
            setappdata(groot, "labkitAppSdkRenderCount", 0);
            renderCleanup = onCleanup(@() ...
                rmappdata(groot, "labkitAppSdkRenderCount"));
            layout = labkit.app.layout.workbench({ ...
                labkit.app.layout.button("refreshStatus", "Refresh status", ...
                    @refreshStatusOnly, Tooltip="Refresh only status text."), ...
                labkit.app.layout.statusPanel("refreshSummary"), ...
                labkit.app.layout.plotArea("stablePlot", @countStablePlot)});
            app = AppSdkSpec.definition(layout, ...
                "CreateState", @createStablePlotSessionState, ...
                "PresentWorkbench", @presentStablePlot);
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            journal = labkittest.temporarySessionJournal(app, root);
            runtime = labkit.app.internal.runtime.RuntimeFactory.createMatlab( ...
                app, [], struct(), journal);
            cleanup = onCleanup(@() runtime.close());
            initialCount = getappdata(groot, "labkitAppSdkRenderCount");

            runtime.invokeAction("refreshStatus");

            testCase.verifyEqual(initialCount, 1);
            testCase.verifyEqual( ...
                getappdata(groot, "labkitAppSdkRenderCount"), 1, ...
                "An unchanged renderer model must not touch native axes.");
            clear cleanup renderCleanup
        end

        function semanticPlotRevisionPreservesStyleRefreshAndRefitsDomain(testCase)
            layout = labkit.app.layout.workbench({ ...
                labkit.app.layout.button("changeStyle", "Change style", ...
                    @changeViewportStyle, Tooltip="Change plot styling."), ...
                labkit.app.layout.button("changeDomain", "Change domain", ...
                    @changeViewportDomain, Tooltip="Change plotted data domain."), ...
                labkit.app.layout.plotArea("revisionPlot", @drawRevisionPlot)});
            app = AppSdkSpec.definition(layout, ...
                "CreateState", @createViewportSessionState, ...
                "PresentWorkbench", @presentViewportRevision);
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            journal = labkittest.temporarySessionJournal(app, root);
            runtime = labkit.app.internal.runtime.RuntimeFactory.createMatlab( ...
                app, [], struct(), journal);
            cleanup = onCleanup(@() runtime.close());
            ax = oneTagged(runtime.figureHandle(), "revisionPlot.main");
            ax.XLim = [0.2 0.8];
            ax.YLim = [0.2 0.8];

            runtime.invokeAction("changeStyle");
            testCase.verifyEqual(ax.XLim, [0.2 0.8], AbsTol=1e-12);
            testCase.verifyEqual(ax.YLim, [0.2 0.8], AbsTol=1e-12);

            runtime.invokeAction("changeDomain");
            testCase.verifyEqual(ax.XLim, [0 2], AbsTol=1e-12);
            testCase.verifyEqual(ax.YLim, [0 2], AbsTol=1e-12);
            clear cleanup
        end

        function popoutPreservesVisibleGraphicsWithHiddenHandles(testCase)
            existingFigures = findall(groot, "Type", "figure");
            sourceFigure = figure("Visible", "off");
            cleanup = onCleanup(@() closeNewFigures(existingFigures));
            sourceAxes = axes(sourceFigure);
            plot(sourceAxes, 1:3, 1:3, DisplayName="data");
            hold(sourceAxes, "on");
            plot(sourceAxes, 1:3, 2:4, HandleVisibility="off");
            hold(sourceAxes, "off");
            labkit.app.internal.native.enableAxesPopout(sourceAxes);
            menu = findall(sourceFigure, "Tag", "labkitAxesPopoutMenu");

            menu.MenuSelectedFcn(menu, []);
            drawnow;

            figures = setdiff(findall(groot, "Type", "figure"), ...
                [existingFigures; sourceFigure]);
            testCase.verifyNumElements(figures, 1);
            popped = figures(1);
            poppedAxes = findall(popped, "Type", "axes");
            testCase.verifyNumElements(findall(poppedAxes, "Type", "line"), 2);
            testCase.verifyNumElements(findall(popped, ...
                "Tag", "labkitAxesPopoutStudioTool"), 1);
            clear cleanup
        end

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
            testCase.verifyEqual(string(summary.WordWrap), "on");
            testCase.verifyEqual(string(summary.Editable), "off");
            testCase.verifyEqual(string(compact.Tooltip), "Ready");
            testCase.verifyClass(compact.Parent, ...
                "matlab.ui.container.GridLayout");
            policy = labkit.app.internal.native.NativeAdapterValues.layoutPolicy();
            testCase.verifyEqual(compact.Parent.Padding, ...
                policy.ReadonlyInset);
            summaryHeight = labkit.app.internal.native.NativeAdapterValues.readonlyHeight( ...
                summary.Value, policy.ReadonlyDefaultWidth, summary.FontSize);
            compactHeight = labkit.app.internal.native.NativeAdapterValues.readonlyHeight( ...
                compact.Value, policy.ReadonlyDefaultWidth, compact.FontSize);
            testCase.verifyGreaterThan(summaryHeight, compactHeight);
            charHeight = labkit.app.internal.native.NativeAdapterValues.readonlyHeight( ...
                'Ready', 210, 12);
            stringHeight = labkit.app.internal.native.NativeAdapterValues.readonlyHeight( ...
                "Ready", 210, 12);
            testCase.verifyEqual(charHeight, stringHeight);
            clear cleanup
        end

        function compactFilePanelShowsFilenameAndRetainsFullPath(testCase)
            layout = labkit.app.layout.workbench({ ...
                labkit.app.layout.fileList("files", ...
                    Bind="project.inputs.sources", ...
                    SelectionMode="single", MaxFiles=1)});
            app = AppSdkSpec.definition(layout, ...
                "CreateState", @createSourceState, ...
                "PresentWorkbench", @presentCompactSource);
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            journal = labkittest.temporarySessionJournal(app, root);
            runtime = labkit.app.internal.runtime.RuntimeFactory.createMatlab( ...
                app, [], struct(), journal);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();
            filepath = fullfile(root, "nested", ...
                "descriptive-source-recording.mat");

            runtime.applyFileSelection("files", filepath, 1);

            status = oneTagged(figureValue, "files.status");
            choose = oneTagged(figureValue, "files.choose");
            testCase.verifyClass(status, "matlab.ui.control.TextArea");
            testCase.verifyEqual(string(status.Editable), "off");
            testCase.verifyEqual(string(status.WordWrap), "on");
            testCase.verifyEqual(string(status.Value), ...
                "descriptive-source-recording.mat");
            testCase.verifyEqual(string(status.Tooltip), string(filepath));
            testCase.verifyGreaterThan(status.Position(4), choose.Position(4));
            clear cleanup
        end

        function nativeInputBridgeDispatchesEverySemanticControl(testCase)
            layout = nativeBridgeLayout();
            app = AppSdkSpec.definition(layout, ...
                "CreateState", @createNativeBridgeSessionState);
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
            invokeNativeCallback( ...
                spinner.ValueChangingFcn, spinner, ...
                struct("Value", 0.05));
            testCase.verifyEqual(spinner.Value, 0);
            testCase.verifyEqual(slider.Value, 0.05);
            spinnerValues = [0.1 0.2 0.3 0.4];
            for index = 1:numel(spinnerValues)
                value = spinnerValues(index);
                spinner.Value = value;
                invokeNativeCallback( ...
                    spinner.ValueChangingFcn, spinner, ...
                    struct("Value", value));
                invokeNativeCallback( ...
                    spinner.ValueChangedFcn, spinner, struct());
                if index == 1
                    testCase.verifyEqual( ...
                        runtime.State.session.sliderValue, value);
                end
                pause(0.05);
            end
            duringSpinner = runtime.diagnosticSnapshot();
            testCase.verifyEqual(runtime.State.session.sliderValue, 0.1);
            duringAliases = actionStartAliases(duringSpinner.events);
            testCase.verifyEqual(sum( ...
                duringAliases == "nativeSlider__valueChanged"), 1);
            pause(0.25);
            drawnow;
            testCase.verifyEqual(runtime.State.session.sliderValue, 0.4);
            afterSpinner = runtime.diagnosticSnapshot();
            spinnerAliases = actionStartAliases(afterSpinner.events);
            testCase.verifyEqual(sum( ...
                spinnerAliases == "nativeSlider__valueChanged"), 2);
            beforeDrag = runtime.diagnosticSnapshot();
            for value = linspace(0.41, 0.6, 20)
                invokeNativeCallback( ...
                    slider.ValueChangingFcn, slider, struct("Value", value));
            end
            duringDrag = runtime.diagnosticSnapshot();
            testCase.verifyEqual(runtime.State.session.sliderValue, 0.4);
            testCase.verifyEqual(duringDrag.totalRecordCount, ...
                beforeDrag.totalRecordCount);
            testCase.verifyEqual(spinner.Value, 0.6, AbsTol=1e-12);
            testCase.verifyEqual(slider.Value, 0.4, AbsTol=1e-12);
            slider.Value = 0.6;
            invokeNativeCallback(slider.ValueChangedFcn, slider, struct());
            afterCommit = runtime.diagnosticSnapshot();
            testCase.verifyGreaterThan(afterCommit.totalRecordCount, ...
                duringDrag.totalRecordCount);
            invokeNativeCallback(slider.ValueChangedFcn, slider, struct());
            afterNoOp = runtime.diagnosticSnapshot();
            testCase.verifyEqual(afterNoOp.totalRecordCount, ...
                afterCommit.totalRecordCount);

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
            events = runtime.diagnosticSnapshot().events;
            aliases = actionStartAliases(events);
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

        function updatesAFieldAndItsCachedLabelWithoutTreeDiscovery(testCase)
            layout = labkit.app.layout.workbench({ ...
                labkit.app.layout.field("gain", Kind="numeric", ...
                    Bind="project.parameters.gain")});
            app = AppSdkSpec.definition(layout, ...
                "CreateState", @createRuntimeState, ...
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
            testCase.verifyEqual(string(label.Enable), "on");
            runtime.applyControlValue("gain", 0);
            testCase.verifyEqual(string(field.Enable), "off");
            testCase.verifyEqual(string(label.Enable), "off");
            clear cleanup
        end

        function updatesSliderTextAsItsLabelWithoutChangingItsValue(testCase)
            layout = labkit.app.layout.workbench({ ...
                labkit.app.layout.slider("dynamicSlider", ...
                    Label="Strength (%)", Limits=[0 100], ...
                    Bind="session.sliderValue", ...
                    OnValueChanged=@changeDynamicSlider)});
            app = AppSdkSpec.definition(layout, ...
                "CreateState", @createDynamicSliderState, ...
                "PresentWorkbench", @presentDynamicSlider);
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            journal = labkittest.temporarySessionJournal(app, root);
            runtime = labkit.app.internal.runtime.RuntimeFactory.createMatlab( ...
                app, [], struct(), journal);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();
            spinner = oneTagged(figureValue, "dynamicSlider");
            label = oneTagged(figureValue, "dynamicSlider.label");

            testCase.verifyEqual(string(label.Text), "Strength (%)");
            runtime.applyControlValue("dynamicSlider", 1);

            testCase.verifyEqual(spinner.Value, 1);
            testCase.verifyEqual(string(label.Text), "Radius (px)");
            clear cleanup
        end

        function keepsDiagnosticStateDestinationWithoutProjectMenus(testCase)
            layout = labkit.app.layout.workbench({ ...
                labkit.app.layout.field("gain", Kind="numeric", ...
                    Bind="project.parameters.gain")});
            app = AppSdkSpec.definition(layout, ...
                "CreateState", @createRuntimeState);
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            journal = labkittest.temporarySessionJournal(app, root);
            runtime = labkit.app.internal.runtime.RuntimeFactory.createMatlab( ...
                app, [], struct(), journal);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();
            screenshotMenu = oneTagged( ...
                figureValue, "labkitAppUtilityScreenshot");
            testCase.verifyEqual(string(screenshotMenu.Text), ...
                "Save to Artifacts");
            screenshotTarget = runtime.automaticArtifactDestination( ...
                "screenshots", "screenshot", ".png");
            testCase.verifyTrue(contains(screenshotTarget, ...
                fullfile("artifacts", "screenshots")));
            testCase.verifyTrue(endsWith(screenshotTarget, ".png"));
            stateTarget = runtime.automaticArtifactDestination( ...
                "states", "state", ".mat");
            testCase.verifyTrue(contains(stateTarget, ...
                fullfile("artifacts", "states")));
            clear cleanup
        end

        function filePanelFailuresAlwaysShowAnAlert(testCase)
            layout = labkit.app.layout.workbench({ ...
                labkit.app.layout.fileList("files", ...
                    Bind="project.inputs.sources", ...
                    SelectionMode="single", MaxFiles=1, ...
                    OnSelectionChanged=@failSourceSelection)});
            app = AppSdkSpec.definition(layout, ...
                "CreateState", @createUnreadableSourceState);
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            journal = labkittest.temporarySessionJournal(app, root);
            runtime = labkit.app.internal.runtime.RuntimeFactory.createMatlab( ...
                app, [], struct(), journal);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();
            list = oneTagged(figureValue, "files");

            invokeNativeCallback(list.ValueChangedFcn, list, []);
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
            app = AppSdkSpec.definition(layout, ...
                "CreateState", @createRuntimeState);
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

        function directManipulationDoesNotShowBusyFeedback(testCase)
            observed = containers.Map("KeyType", "char", ...
                "ValueType", "any");
            observed("busyCount") = 0;
            setappdata(groot, "labkitAppSdkDirectManipulationProbe", observed);
            probeCleanup = onCleanup(@() removeDirectManipulationProbe());
            roi = labkit.app.interaction.rectangle("probeRoi", ...
                @AppSdkSpec.slowDirectManipulationProbe, Axis="main");
            layout = labkit.app.layout.workbench({ ...
                labkit.app.layout.slider("directSlider", ...
                    OnValueChanged=@AppSdkSpec.slowDirectManipulationProbe), ...
                labkit.app.layout.plotArea("directPlot", @drawNothing, ...
                    Interactions={roi})});
            app = AppSdkSpec.definition(layout, ...
                "PresentWorkbench", @presentDirectManipulationProbe);
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            journal = labkittest.temporarySessionJournal(app, root);
            runtime = labkit.app.internal.runtime.RuntimeFactory.createMatlab( ...
                app, [], struct(), journal);
            cleanup = onCleanup(@() runtime.close());
            observed("figure") = runtime.figureHandle();
            testCase.verifyFalse(runtime.StartupFailed);

            runtime.applyControlValue("directSlider", 0.5);
            runtime.applyInteraction( ...
                "probeRoi", "interactionChanged", [0.2 0.2 0.3 0.3]);

            testCase.verifyEqual(observed("busyCount"), 0);
            testCase.verifyEqual(observed("pointer"), "arrow");
            testCase.verifyFalse(contains(observed("title"), "[Working:"));
            clear probeCleanup cleanup
        end

        function privatePrimitivesUsePureMatlabContracts(testCase)
            root = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            testCase.verifyEqual( ...
                labkit.app.internal.filesystem.absolutePath( ...
                    fullfile(root, "one", "..", "two")), ...
                string(fullfile(root, "two")));
            first = labkit.app.internal.identity.newId();
            second = labkit.app.internal.identity.newId();
            testCase.verifyGreaterThan(strlength(first), 0);
            testCase.verifyNotEqual(first, second);
        end
    end

    methods (Static, Access = private)
        function state = quickBusyProbe(state, ~)
            observed = getappdata(groot, "labkitAppSdkBusyProbe");
            figureValue = observed("figure");
            observed("quickBusy") = ...
                isappdata(figureValue, "labkitAppBusy");
            observed("quickPointer") = string(figureValue.Pointer);
            storeMapValue(observed, "quickTitle", string(figureValue.Name));
            secondary = oneTagged(figureValue, "secondary");
            gain = oneTagged(figureValue, "gain");
            secondary.ButtonPushedFcn(secondary, []);
            gain.Value = 7;
            gain.ValueChangedFcn(gain, []);
        end

        function state = slowBusyProbe(state, callbackContext)
            observed = getappdata(groot, "labkitAppSdkBusyProbe");
            pause(0.6);
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
            storeMapValue(observed, "progressTitle", string(figureValue.Name));
        end

        function state = slowDirectManipulationProbe(state, ~, ~)
            pause(0.6);
            drawnow;
            observed = getappdata( ...
                groot, "labkitAppSdkDirectManipulationProbe");
            figureValue = observed("figure");
            if isappdata(figureValue, "labkitAppBusy")
                observed("busyCount") = observed("busyCount") + 1;
            end
            observed("pointer") = string(figureValue.Pointer);
            storeMapValue(observed, "title", string(figureValue.Name));
        end

        function state = secondaryBusyProbe(state, ~)
            observed = getappdata(groot, "labkitAppSdkBusyProbe");
            storeMapValue(observed, "secondaryCount", ...
                observed("secondaryCount") + 1);
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

function values = storeMapValue(values, key, value)
values(char(key)) = value;
end

function handle = oneTagged(parent, tag)
handle = findall(parent, "Tag", tag);
assert(isscalar(handle), "Expected one handle tagged " + tag + ".");
end

function session = createStablePlotSession(~, ~)
session = struct("statusCount", 0);
end

function state = refreshStatusOnly(state, ~)
state.session.statusCount = state.session.statusCount + 1;
end

function view = presentStablePlot(state)
view = labkit.app.view.Snapshot() ...
    .text("refreshSummary", compose("Refresh %d", state.session.statusCount)) ...
    .renderPlot("stablePlot", struct("value", 1));
end

function countStablePlot(~, ~)
count = getappdata(groot, "labkitAppSdkRenderCount");
setappdata(groot, "labkitAppSdkRenderCount", count + 1);
end

function session = createViewportSession(~, ~)
session = struct("domain", 1, "warmColor", false);
end

function state = changeViewportStyle(state, ~)
state.session.warmColor = ~state.session.warmColor;
end

function state = changeViewportDomain(state, ~)
state.session.domain = 2;
end

function view = presentViewportRevision(state)
model = struct("domain", state.session.domain, ...
    "warmColor", state.session.warmColor);
view = labkit.app.view.Snapshot().renderPlot( ...
    "revisionPlot", model, ...
    ViewRevision="domain:" + string(state.session.domain));
end

function drawRevisionPlot(axesById, model)
ax = axesById.main;
labkit.app.plot.clearAxes(ax, ResetScale=true);
color = [0 0.4470 0.7410];
if model.warmColor
    color = [0.8500 0.3250 0.0980];
end
plot(ax, [0 model.domain], [0 model.domain], Color=color);
ax.XLim = [0 model.domain];
ax.YLim = [0 model.domain];
end

function closeNewFigures(existingFigures)
figures = setdiff(findall(groot, "Type", "figure"), existingFigures);
close(figures(isvalid(figures)));
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

function aliases = actionStartAliases(events)
aliases = strings(1, numel(events));
aliasCount = 0;
for index = 1:numel(events)
    event = events(index);
    if event.category == "runtime.interaction" && ...
            endsWith(event.eventName, ".started") && ...
            isfield(event.attributes, "runtimeAlias")
        aliasCount = aliasCount + 1;
        aliases(aliasCount) = string(event.attributes.runtimeAlias);
    end
end
aliases = aliases(1:aliasCount);
end

function observed = capturePostedEvent(observed, eventId, updateState)
observed("eventId") = eventId;
observed("updateState") = updateState;
end

function state = invalidPostedUpdate(inputs)
state = inputs;
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
callbackContext.setResource("postedEventProbe", ...
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

function project = createProject()
project = struct("parameters", struct("gain", 1));
end

function project = createSourceProject()
project = struct("inputs", struct( ...
    "sources", labkit.app.source.emptyRecords()));
end

function accepted = acceptPngPaths(paths)
accepted = endsWith(lower(paths), ".png");
end

function accepted = wrongPathFilter(~, ~)
accepted = true;
end

function store = captureAlert(store, message, title)
store("message") = string(message);
store("title") = string(title);
end

function store = captureDialog(store, kind, message, title)
store("kind") = string(kind);
captureAlert(store, message, title);
end

function state = runProbe(state, ~)
end

function state = changeInteractionProbe(state, ~, ~)
end

function state = startProbe(state, ~)
end

function removeBusyProbe()
if isappdata(groot, "labkitAppSdkBusyProbe")
    rmappdata(groot, "labkitAppSdkBusyProbe");
end
end

function removeDirectManipulationProbe()
if isappdata(groot, "labkitAppSdkDirectManipulationProbe")
    rmappdata(groot, "labkitAppSdkDirectManipulationProbe");
end
end

function view = presentDirectManipulationProbe(~)
view = labkit.app.view.Snapshot() ...
    .renderPlot("directPlot", struct()) ...
    .rectangle("probeRoi", [0.1 0.1 0.2 0.2]);
end

function session = createSession(~, ~)
session = struct();
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

function state = createDynamicSliderState(~, ~)
state = struct("project", struct(), ...
    "session", struct("sliderValue", 0));
end

function state = changeDynamicSlider(state, value, ~)
state.session.sliderValue = value;
end

function view = presentDynamicSlider(state)
label = "Strength (%)";
if state.session.sliderValue > 0
    label = "Radius (px)";
end
view = labkit.app.view.Snapshot() ...
    .text("dynamicSlider", label);
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

function state = createRuntimeState(context, initialInput)
state = createTestState(context, initialInput, @createProject, @emptySession);
end

function state = createSourceState(context, initialInput)
state = createTestState( ...
    context, initialInput, @createSourceProject, @emptySession);
end

function state = createUnreadableSourceState(context, initialInput)
state = createTestState( ...
    context, initialInput, @createUnreadableSourceProject, @emptySession);
end

function state = createSessionState(context, initialInput)
state = createTestState(context, initialInput, @() struct(), @createSession);
end

function state = createPostedEventSessionState(context, initialInput)
state = createTestState( ...
    context, initialInput, @() struct(), @createPostedEventSession);
end

function state = createStablePlotSessionState(context, initialInput)
state = createTestState( ...
    context, initialInput, @() struct(), @createStablePlotSession);
end

function state = createViewportSessionState(context, initialInput)
state = createTestState( ...
    context, initialInput, @() struct(), @createViewportSession);
end

function state = createNativeBridgeSessionState(context, initialInput)
state = createTestState( ...
    context, initialInput, @() struct(), @createNativeBridgeSession);
end

function state = createTestState( ...
        context, initialInput, projectFactory, sessionFactory)
if isempty(initialInput)
    project = projectFactory();
else
    project = initialInput;
end
state = struct("project", project, ...
    "session", sessionFactory(project, context));
end

function session = emptySession(~, ~)
session = struct();
end

function session = wrongSession(~)
session = struct();
end

function view = presentGainAvailability(state)
view = labkit.app.view.Snapshot().enabled( ...
    "gain", state.project.parameters.gain ~= 0);
end

function view = presentCompactSource(applicationState)
paths = labkit.app.source.paths(applicationState.project.inputs.sources);
text = "No files selected";
if ~isempty(paths)
    text = paths(1);
end
view = labkit.app.view.Snapshot().text("files", text);
end

function project = createUnreadableSourceProject()
project = createSourceProject();
project.inputs.sources = labkit.app.source.record( ...
    "source1", "files", "unreadable.dat");
end

function output = failSourceSelection(~, ~, ~)
output = MException( ...
    "probe:UnreadableSource", "Synthetic source parse failure.");
throw(output);
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
