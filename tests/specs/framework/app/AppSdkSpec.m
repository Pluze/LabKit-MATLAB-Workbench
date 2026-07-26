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
                app, [], struct(), labkit.app.diagnostic.Options(), journal);
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
                "BuildDebugSample", @debugSample);

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
            context = labkit.app.internal.CallbackContextFactory.disconnected();

            testCase.verifyTrue(meta.class.fromName( ...
                "labkit.app.CallbackContext").Sealed);
            testCase.verifyFalse(any(string(properties(context)) == "Backend"));
            testCase.verifyError(@() context.alert("message", "title"), ...
                "labkit:app:runtime:InvariantFailure");
        end

        function syntheticDebugStartsWithACleanProjectAndNoStartupAction(testCase)
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture).Folder;
            layout = labkit.app.layout.workbench({ ...
                labkit.app.layout.field("gain", Kind="numeric", ...
                    Bind="project.parameters.gain")});
            app = AppSdkSpec.definition(layout, "ProjectSchema", ...
                labkit.app.project.Schema(Version=1, Create=@createProject, ...
                Validate=@validateProject), CreateSession=@sampleSession, ...
                OnStart=@startChangesGain, BuildDebugSample=@validDebugSample);
            diagnostics = labkit.app.diagnostic.Options( ...
                ArtifactFolder=folder, Sample="synthetic");
            journal = labkittest.temporarySessionJournal(app, folder);
            runtime = labkit.app.internal.RuntimeFactory.createHeadless( ...
                app, [], struct(), diagnostics, journal);
            cleanup = onCleanup(@() runtime.close());

            testCase.verifyEqual(runtime.State.project.parameters.gain, 1);
            testCase.verifyEqual(runtime.State.session.gainAtCreation, 1);
            testCase.verifyTrue(isfile(fullfile(folder, "sample-pack.json")));
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
                app, [], struct(), labkit.app.diagnostic.Options(), journal);
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
                app, [], struct(), labkit.app.diagnostic.Options(), journal);
            cleanup = onCleanup(@() runtime.close());
            figureValue = runtime.figureHandle();
            field = findall(figureValue, "Tag", "gain");
            label = findall(figureValue, "Tag", "gain.label");

            testCase.verifyEqual(string(field.Enable), "on");
            testCase.verifyEqual(string(label.Enable), "on");
            runtime.applyBinding("gain", 0);
            testCase.verifyEqual(string(field.Enable), "off");
            testCase.verifyEqual(string(label.Enable), "off");
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

function pack = debugSample(~)
pack = struct();
end

function session = sampleSession(project, ~)
session = struct("gainAtCreation", project.parameters.gain);
end

function state = startChangesGain(state, ~)
state.project.parameters.gain = 99;
end

function pack = validDebugSample(~)
pack = labkit.app.diagnostic.SamplePack( ...
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
