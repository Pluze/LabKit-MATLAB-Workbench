classdef UiProjectDocumentStoreTest < matlab.unittest.TestCase
    methods (Test)
        function savesAndRestoresCurrentEnvelope(testCase)
            setupLabKitTestPath();
            folder = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            path = fullfile(string(folder.Folder), "current.mat");
            app = documentApplication();
            runtime = app.createRuntimeForTesting();
            state = struct("project", struct("value", 7), ...
                "session", struct("token", "resume-token"));

            saved = runtime.saveProject(state, path);
            raw = load(path, "labkitProject");
            runtime.restoreProject(path, false);
            restored = runtime.State;
            metadata = runtime.documentMetadata();

            testCase.verifyFalse(saved.Cancelled);
            testCase.verifyEqual(saved.Value, path);
            testCase.verifyEqual(raw.labkitProject.format, "labkit.project");
            testCase.verifyEqual(raw.labkitProject.formatVersion.major, 1);
            testCase.verifyEqual(raw.labkitProject.app.id, "probe.document");
            testCase.verifyEqual(raw.labkitProject.app.payloadVersion, 2);
            testCase.verifyEqual(raw.labkitProject.producer.appVersion, "1.2.3");
            testCase.verifyEqual(restored.project.value, 7);
            testCase.verifyEqual(restored.session.token, "resume-token");
            testCase.verifyEqual(metadata.path, path);
            testCase.verifyFalse(metadata.dirty);
        end

        function migratesCurrentAndImportsDeclaredLegacyOnly(testCase)
            setupLabKitTestPath();
            folder = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            app = documentApplication();
            runtime = app.createRuntimeForTesting();
            currentPath = fullfile(string(folder.Folder), "v1.mat");
            legacyPath = fullfile(string(folder.Folder), "legacy.mat");
            envelope = currentEnvelope("probe.document", 1, struct("value", 4));
            labkitProject = envelope;
            save(currentPath, "labkitProject");
            legacyProject = 9;
            save(legacyPath, "legacyProject");

            runtime.restoreProject(currentPath, false);
            migrated = runtime.State;
            runtime.restoreProject(legacyPath, true);
            legacy = runtime.State;
            legacyMetadata = runtime.documentMetadata();

            testCase.verifyEqual(migrated.project.value, 5);
            testCase.verifyEqual(legacy.project.value, 9);
            testCase.verifyEqual(legacy.session.token, "legacy");
            testCase.verifyEqual(legacyMetadata.path, "");
            testCase.verifyTrue(legacyMetadata.dirty);
        end

        function rejectsWrongAppAndNewerPayloadWithoutMutatingMetadata(testCase)
            setupLabKitTestPath();
            folder = testCase.applyFixture(matlab.unittest.fixtures.TemporaryFolderFixture);
            app = documentApplication();
            runtime = app.createRuntimeForTesting();
            original = runtime.documentMetadata();
            wrongPath = fullfile(string(folder.Folder), "wrong.mat");
            newerPath = fullfile(string(folder.Folder), "newer.mat");
            labkitProject = currentEnvelope("other.app", 2, struct("value", 1));
            save(wrongPath, "labkitProject");
            labkitProject = currentEnvelope("probe.document", 3, struct("value", 1));
            save(newerPath, "labkitProject");

            testCase.verifyError(@() runtime.restoreProject(wrongPath, false), ...
                "labkit:ui:runtime:WrongProjectApp");
            testCase.verifyEqual(runtime.documentMetadata(), original);
            testCase.verifyError(@() runtime.restoreProject(newerPath, false), ...
                "labkit:ui:runtime:NewerProjectPayload");
            testCase.verifyEqual(runtime.documentMetadata(), original);
        end

        function failedSaveDoesNotMutateMetadata(testCase)
            setupLabKitTestPath();
            app = documentApplication();
            runtime = app.createRuntimeForTesting();
            original = runtime.documentMetadata();
            state = struct("project", struct("value", 1), ...
                "session", struct("token", "unsaved"));

            testCase.verifyError(@() runtime.saveProject(state, ...
                fullfile(tempdir, "missing-document-folder", "project.mat")), ...
                "labkit:ui:runtime:ProjectWriteFailed");
            testCase.verifyEqual(runtime.documentMetadata(), original);
        end

        function failedPlatformCommitDoesNotPublishRestoredDocument(testCase)
            setupLabKitTestPath();
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture);
            path = fullfile(string(folder.Folder), "candidate.mat");
            app = documentApplication();
            runtime = app.createRuntimeForTesting();
            originalState = runtime.State;
            originalMetadata = runtime.documentMetadata();
            labkitProject = currentEnvelope( ...
                "probe.document", 2, struct("value", 12));
            save(path, "labkitProject");
            runtime.failNextCommit();

            testCase.verifyError(@() runtime.restoreProject(path, false), ...
                "labkit:ui:runtime:ProjectRestoreFailed");
            testCase.verifyEqual(runtime.State, originalState);
            testCase.verifyEqual(runtime.documentMetadata(), originalMetadata);
        end

        function filePanelBindingOwnsPortableProjectSources(testCase)
            setupLabKitTestPath();
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture);
            projectFolder = fullfile(string(folder.Folder), "projects");
            sourceFolder = fullfile(string(folder.Folder), "sources");
            mkdir(projectFolder);
            mkdir(sourceFolder);
            sourcePath = fullfile(sourceFolder, "trace.csv");
            file = fopen(sourcePath, "w");
            cleaner = onCleanup(@() fclose(file));
            fprintf(file, "time,value\n0,1\n");
            clear cleaner
            projectPath = fullfile(projectFolder, "bound.mat");
            runtime = sourceDocumentApplication().createRuntimeForTesting();
            state = runtime.State;
            state.project.inputs.sources = runtime.sourceRecord( ...
                "trace", "recording", sourcePath, true);

            runtime.saveProject(state, projectPath);
            saved = load(projectPath, "labkitProject");
            runtime.restoreProject(projectPath, false);
            paths = runtime.sourcePaths( ...
                runtime.State.project.inputs.sources, strings(0, 1));

            testCase.verifyEqual( ...
                saved.labkitProject.sources.reference.relativePath, ...
                "../sources/trace.csv");
            testCase.verifyEqual( ...
                saved.labkitProject.payload.inputs.sources.reference.relativePath, ...
                "../sources/trace.csv");
            testCase.verifyEqual(paths, string(sourcePath));
        end

        function missingRequiredBoundSourceRejectsRestore(testCase)
            setupLabKitTestPath();
            folder = testCase.applyFixture( ...
                matlab.unittest.fixtures.TemporaryFolderFixture);
            sourcePath = fullfile(string(folder.Folder), "temporary.csv");
            file = fopen(sourcePath, "w");
            cleaner = onCleanup(@() fclose(file));
            fprintf(file, "synthetic");
            clear cleaner
            projectPath = fullfile(string(folder.Folder), "bound.mat");
            runtime = sourceDocumentApplication().createRuntimeForTesting();
            state = runtime.State;
            state.project.inputs.sources = runtime.sourceRecord( ...
                "trace", "recording", sourcePath, true);
            runtime.saveProject(state, projectPath);
            delete(sourcePath);
            restored = sourceDocumentApplication().createRuntimeForTesting();
            original = restored.State;

            testCase.verifyError(@() ...
                restored.restoreProject(projectPath, false), ...
                "labkit:ui:runtime:MissingProjectSource");
            testCase.verifyEqual(restored.State, original);
        end
    end
end

function app = documentApplication()
project = labkit.ui.ProjectContract(Version=2, Create=@createProject, ...
    Validate=@validateProject, Migrate=@migrateProject, ...
    LegacyImports=struct("legacyProject", @importLegacy), ...
    CreateResume=@createResume, ApplyResume=@applyResume);
app = labkit.ui.Application(Command="labkit_DocumentProbe_app", ...
    Id="probe.document", Title="Document", Family="Tests", ...
    AppVersion="1.2.3", Updated="2026-07-19", Requirements=[], ...
    Project=project, Session=@createSession, ...
    Layout=labkit.ui.Layout.workbench({labkit.ui.Layout.field("value")}), ...
    Present=@present, Capabilities="project");
end

function project = createProject()
project = struct("value", 0);
end

function accepted = validateProject(project)
accepted = isstruct(project) && isscalar(project) && isfield(project, "value") && ...
    isnumeric(project.value) && isscalar(project.value) && project.value >= 0;
end

function project = migrateProject(project, fromVersion)
project.value = project.value + fromVersion;
end

function [project, resume] = importLegacy(value)
project = struct("value", value);
resume = struct("token", "legacy");
end

function session = createSession(~)
session = struct("token", "fresh");
end

function resume = createResume(session, ~)
resume = struct("token", session.token);
end

function session = applyResume(session, resume, ~)
session.token = resume.token;
end

function view = present(state)
view = labkit.ui.Presentation().value("value", state.project.value);
end

function app = sourceDocumentApplication()
project = labkit.ui.ProjectContract(Version=1, ...
    Create=@createSourceProject, Validate=@validateSourceProject);
layout = labkit.ui.Layout.workbench({ ...
    labkit.ui.Layout.filePanel("sources", ...
        Bind="project.inputs.sources")});
app = labkit.ui.Application(Command="labkit_SourceDocumentProbe_app", ...
    Id="probe.source.document", Title="Source document", Family="Tests", ...
    AppVersion="1.0.0", Updated="2026-07-19", Requirements=[], ...
    Project=project, Layout=layout);
end

function project = createSourceProject()
project = struct("inputs", struct("sources", struct([])));
end

function accepted = validateSourceProject(project)
accepted = isstruct(project) && isscalar(project) && ...
    isfield(project, "inputs") && isstruct(project.inputs) && ...
    isscalar(project.inputs) && isfield(project.inputs, "sources") && ...
    isstruct(project.inputs.sources);
end

function envelope = currentEnvelope(appId, payloadVersion, payload)
envelope = struct("format", "labkit.project", ...
    "formatVersion", struct("major", 1, "minor", 0), ...
    "app", struct("id", appId, "payloadVersion", payloadVersion), ...
    "document", struct("id", "document-id", ...
        "createdAtUtc", "2026-01-01T00:00:00Z", ...
        "modifiedAtUtc", "2026-01-01T00:00:00Z", "revision", uint64(0)), ...
    "producer", struct("appVersion", "1.0.0"), ...
    "payload", payload, "resume", struct("token", "from-file"));
end
