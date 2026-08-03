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
            runtime = labkit.app.internal.RuntimeFactory.createHeadless( ...
                app, [], struct(), journal);
            cleanup = onCleanup(@() runtime.close());

            runtime.applyBinding("gain", 3);

            testCase.verifyEqual(runtime.State.project.parameters.gain, 3);
            testCase.verifyEqual(labkit.app.internal.DefinitionInspector.signalIds(app), ...
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

        function rejectsRetiredLaunchDiagnosticsOption(testCase)
            app = AppSdkSpec.definition(labkit.app.layout.workbench({}));

            testCase.verifyError(@() app.launch( ...
                Diagnostics=struct()), ...
                "labkit:app:contract:UnknownArgument");
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
            context = labkit.app.internal.CallbackContextFactory.disconnected();

            testCase.verifyTrue(meta.class.fromName( ...
                "labkit.app.CallbackContext").Sealed);
            testCase.verifyFalse(any(string(properties(context)) == "Backend"));
            testCase.verifyError(@() context.alert("message", "title"), ...
                "labkit:app:runtime:InvariantFailure");
        end

        function nativeDialogFiltersContainOnlyLegacyCharacterCells(testCase)
            filters = labkit.app.internal.NativeAdapterValues.dialogFilters( ...
                {"*.zip", "Diagnostic bundle (*.zip)"});
            scalarFilter = ...
                labkit.app.internal.NativeAdapterValues.dialogFilters("*.png");
            characterFilter = ...
                labkit.app.internal.NativeAdapterValues.dialogFilters('*.tif');

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
            labels = labkit.app.internal.NativeAdapterValues.formatFileLabels( ...
                windowsPath, 'ready');
            fileCancellation = ...
                labkit.app.internal.NativeAdapterValues.dialogPath(0, 0);
            folderCancellation = ...
                labkit.app.internal.NativeAdapterValues.folderDialogPath(0);

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

            labkit.app.internal.NativeAdapterValues.rememberDialogFolder( ...
                "input", inputFolder);
            labkit.app.internal.NativeAdapterValues.rememberDialogFolder( ...
                "output", outputFolder);

            testCase.verifyEqual(string( ...
                labkit.app.internal.NativeAdapterValues.dialogStartFolder( ...
                "input", "")), string(inputFolder));
            testCase.verifyEqual(string( ...
                labkit.app.internal.NativeAdapterValues.dialogStartFolder( ...
                "output", "")), string(outputFolder));
            testCase.verifyEqual(string( ...
                labkit.app.internal.NativeAdapterValues.dialogStartFolder( ...
                "input", outputFolder)), string(outputFolder), ...
                "An explicit valid start folder must override remembered state.");
            labkit.app.internal.NativeAdapterValues.rememberDialogFolder( ...
                "input", fullfile(root, "missing"));
            testCase.verifyEqual(string( ...
                labkit.app.internal.NativeAdapterValues.dialogStartFolder( ...
                "input", "")), string(inputFolder), ...
                "An invalid or cancelled choice must preserve remembered state.");
            clear cleanup
        end

        function sourceResolutionTreatsCharacterIdAsOneIdentifier(testCase)
            backend = struct("sourcePaths", @sourcePathsProbe);
            context = labkit.app.internal.CallbackContextFactory.create(backend);

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
            runtime = labkit.app.internal.RuntimeFactory.createHeadless( ...
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
            runtime = labkit.app.internal.RuntimeFactory.createHeadless( ...
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
            runtime = labkit.app.internal.RuntimeFactory.createHeadless( ...
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
            runtime = labkit.app.internal.RuntimeFactory.createHeadless( ...
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
            runtime = labkit.app.internal.RuntimeFactory.createHeadless( ...
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

        function explicitSourceBindingsPreserveLegacyInference(testCase)
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
    end

    methods (Test, TestTags = {'Contract:source', 'Env:hidden-gui'})
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
            runtime = labkit.app.internal.RuntimeFactory.createMatlab( ...
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
            runtime = labkit.app.internal.RuntimeFactory.createMatlab( ...
                app, [], struct(), journal);
            cleanup = onCleanup(@() runtime.close());

            menu = findall(runtime.figureHandle(), ...
                "Tag", "labkitAppUtilitySyntheticInputs");

            testCase.verifyNumElements(menu, 1);
            testCase.verifyEqual(string(menu.Text), ...
                "Generate Synthetic Inputs...");
            clear cleanup
        end
    end

    methods (Static, Access = private)
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

function accepted = validateProject(project)
accepted = isstruct(project) && isscalar(project) && ...
    isfield(project, "parameters") && isstruct(project.parameters) && ...
    isfield(project.parameters, "gain") && isfinite(project.parameters.gain);
end

function state = runProbe(state, ~)
end

function state = startProbe(state, ~)
end

function session = createSession(~, ~)
session = struct();
end

function view = presentProbe(~)
view = labkit.app.view.Snapshot();
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
