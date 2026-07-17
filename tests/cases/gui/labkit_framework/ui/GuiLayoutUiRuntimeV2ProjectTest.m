classdef GuiLayoutUiRuntimeV2ProjectTest < matlab.unittest.TestCase
    %GUILAYOUTUIRUNTIMEV2PROJECTTEST Verify durable V2 project documents.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function project_roundtrip_migration_and_failures_are_atomic(~)
            setupLabKitTestPath();
            verifyProjectDocuments();
        end

        function minimal_definition_needs_no_app_lifecycle_callbacks(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());
            info = labkit.ui.runtime.launch(@minimalDefinition, "version");
            req = labkit.ui.runtime.launch(@minimalDefinition, "requirements");
            testCase.verifyEqual(info.name, "minimal_definition_probe");
            testCase.verifyEqual(req.type, "labkit.requirements");
            fig = labkit.ui.runtime.launch(@minimalDefinition);
            h.waitForUiIdle(fig);
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            testCase.verifyEqual(string(fieldnames(runtime.state.project)), ...
                ["inputs"; "parameters"; "annotations"; "results"; "extensions"]);
            testCase.verifyEqual(string(fieldnames(runtime.state.session)), ...
                ["selection"; "workflow"; "view"; "cache"]);
            testCase.verifyEmpty(fieldnames(runtime.definition.actions));
            clear cleanup
        end

        function project_migration_contract_rejects_missing_or_ambiguous_callbacks(testCase)
            setupLabKitTestPath();
            missing = struct("Version", 2, "Create", @createProject, ...
                "Validate", @validateProject);
            both = struct("Version", 2, "Create", @createProject, ...
                "Validate", @validateProject, "Migrate", @migrateProject, ...
                "Migrations", {{@migrateOneToTwo}});
            testCase.verifyError(@() projectDefinition(missing), ...
                'labkit:ui:runtime:InvalidDefinition');
            testCase.verifyError(@() projectDefinition(both), ...
                'labkit:ui:runtime:InvalidDefinition');
        end
    end
end

function def = projectDefinition(project)
    def = labkit.ui.runtime.define( ...
        "Id", "project_definition_probe", ...
        "Title", "Project Definition Probe", ...
        "Project", project, ...
        "Layout", @() struct());
end

function def = minimalDefinition()
    def = labkit.ui.runtime.define( ...
        "Command", "minimal_definition_probe", ...
        "Id", "minimal_definition_probe", ...
        "Title", "Minimal Definition Probe", ...
        "Family", "Test", ...
        "AppVersion", "1.0.0", ...
        "Updated", "2026-07-16", ...
        "Requirements", labkit.contract.requirements(), ...
        "Layout", @minimalLayout);
end

function layout = minimalLayout()
    layout = labkit.ui.layout.workbench( ...
        "minimal_definition_probe", "Minimal Definition Probe", ...
        "controlTabs", {labkit.ui.layout.tab("main", "Main", { ...
            labkit.ui.layout.section("content", "Content", { ...
                labkit.ui.layout.field("message", "Message", ...
                    "value", "Ready")})})}, ...
        "workspace", labkit.ui.layout.workspace( ...
            "workspace", "Workspace", {}));
end

function verifyProjectDocuments()
    h = guiTestHelpers();
    h.assertUifigureAvailable();
    oldMode = getenv('LABKIT_GUI_TEST_MODE');
    setenv('LABKIT_GUI_TEST_MODE', 'hidden');
    cleanupMode = onCleanup(@() setenv('LABKIT_GUI_TEST_MODE', oldMode));
    cleanupFigures = onCleanup(@() h.closeAllFigures());
    folder = string(tempname);
    mkdir(folder);
    cleanupFolder = onCleanup(@() rmdir(folder, 's'));
    fig = labkit.ui.runtime.launch(@definition, @requirements, @versionInfo);
    h.waitForUiIdle(fig);
    ui = getappdata(fig, 'labkitUiRegistry');
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    runtime.request.recoveryRoot = fullfile(folder, "recovery");
    runtime.request.autosaveDelay = 0.05;
    runtime.request.resultFolder = fullfile(folder, "result");
    setappdata(fig, 'labkitUiAppRuntime', runtime);
    invoke(ui.controls.increment.button);
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    assert(runtime.document.dirty && endsWith(string(fig.Name), " *"), ...
        'A durable project edit should mark the document and title dirty.');
    pause(0.15);
    drawnow;
    recoveryPath = string(getappdata(fig, 'labkitV2RecoveryFile'));
    assert(isfile(recoveryPath), ...
        'Idle successful project commits should write debounced recovery.');
    [documentFolder, ~, ~] = fileparts(recoveryPath);
    [~, appStorageFolder, ~] = fileparts(fileparts(documentFolder));
    assert(startsWith(string(appStorageFolder), "app_") && ...
        string(appStorageFolder) ~= "runtime_v2_project_probe", ...
        'Recovery storage must use a collision-free app identity key.');

    invoke(ui.controls.export.button);
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    manifestPath = runtime.state.project.results.manifestPath;
    manifest = jsondecode(fileread(manifestPath));
    assert(string(manifest.format) == "labkit.result" && ...
        string(manifest.run.status) == "partial" && ...
        manifest.outputs(1).bytes == 4 && ...
        strlength(string(manifest.outputs(1).sha256)) == 64 && ...
        string(manifest.outputs(2).status) == "failed", ...
        'Result service should record hashes, sizes, and partial failures.');
    pause(0.15);
    drawnow;
    assert(isfile(fullfile(fileparts(recoveryPath), "previous.mat")), ...
        'Recovery policy should retain one bounded previous generation.');
    beforeBadExport = getappdata(fig, 'labkitUiAppRuntime');
    assertThrows(@() invoke(ui.controls.badExport.button), ...
        'labkit:ui:runtime:InvalidResultManifest');
    assertRuntimeUnchanged(fig, beforeBadExport, ...
        'Result path traversal rejection must not commit semantic state.');
    assertThrows(@() invoke(ui.controls.duplicateExport.button), ...
        'labkit:ui:runtime:InvalidResultManifest');

    currentPath = fullfile(folder, "current.mat");
    labkit.ui.runtime.saveState(fig, currentPath);
    stored = load(currentPath, 'labkitProject');
    assert(string(stored.labkitProject.format) == "labkit.project" && ...
        stored.labkitProject.app.payloadVersion == 3 && ...
        ~isfield(stored.labkitProject.payload, 'session') && ...
        stored.labkitProject.resume.generation == 1, ...
        ['V2 save should write durable project state plus only the ' ...
        'app-declared best-effort resume payload.']);
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    assert(~runtime.document.dirty && runtime.document.path == currentPath, ...
        'Successful explicit save should register the path and mark clean.');

    portableRoot = fullfile(folder, "portable-root");
    portableStateFolder = fullfile(portableRoot, "state");
    portableSourceFolder = fullfile(portableRoot, "source");
    mkdir(portableStateFolder);
    mkdir(portableSourceFolder);
    sourcePath = fullfile(portableSourceFolder, "portable-input.dat");
    writeBytes(sourcePath, uint8([5 6 7]));
    source = struct("id", "requiredInput", "required", true, ...
        "role", "input", "reference", struct( ...
            "schemaVersion", 1, "relativePath", "", ...
            "originalPath", sourcePath, "fileName", "portable-input.dat", ...
            "futureReferenceField", "preserved"));
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    runtime.state.project.inputs.sources = source;
    setappdata(fig, 'labkitUiAppRuntime', runtime);
    portablePath = fullfile(portableStateFolder, "portable.mat");
    labkit.ui.runtime.saveState(fig, portablePath);
    portable = load(portablePath, 'labkitProject');
    savedReference = portable.labkitProject.payload.inputs.sources.reference;
    assert(savedReference.relativePath == "../source/portable-input.dat" && ...
        savedReference.futureReferenceField == "preserved", ...
        ['Saving must derive the relative source path from the actual ' ...
        'destination and preserve additive reference fields.']);
    movedRoot = fullfile(folder, "moved-portable-root");
    movefile(portableRoot, movedRoot);
    movedPortablePath = fullfile(movedRoot, "state", "portable.mat");
    movedSourcePath = fullfile(movedRoot, "source", "portable-input.dat");
    labkit.ui.runtime.loadState(fig, movedPortablePath);
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    assert(runtime.state.project.inputs.sources.reference.originalPath == ...
        movedSourcePath && ...
        runtime.state.session.cache.sourcePath == movedSourcePath, ...
        ['A save-generated relative reference must survive moving the ' ...
        'project/source directory tree before fresh session creation.']);

    invoke(ui.controls.increment.button);
    assert(getappdata(fig, 'labkitUiAppRuntime').state.project.parameters.count == 2);
    labkit.ui.runtime.loadState(fig, currentPath);
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    assert(runtime.state.project.parameters.count == 1 && ...
        runtime.state.session.cache.generation == 1 && ...
        runtime.state.session.cache.resumedGeneration == 1 && ...
        ~runtime.document.dirty, ...
        'Open should replace project, construct a fresh session, and mark clean.');
    previewAxes = ui.controls.preview.axesById.axis1;
    cla(previewAxes);
    labkit.ui.runtime.loadState(fig, currentPath);
    assert(~isempty(previewAxes.Children), ...
        ['Opening the same project must repaint previews instead of treating ' ...
        'the previous document presentation as a current render cache.']);

    recoveredFig = labkit.ui.runtime.launch(@definition, @requirements, ...
        @versionInfo, "RequestAdapter", @(args) recoveryRequest( ...
        args, recoveryPath));
    recoveredRuntime = getappdata(recoveredFig, 'labkitUiAppRuntime');
    assert(recoveredRuntime.document.dirty && ...
        strlength(recoveredRuntime.document.path) == 0, ...
        'Recovered documents should open dirty and never own the explicit path.');
    delete(recoveredFig);

    additive = stored.labkitProject;
    additive.formatVersion.minor = 9;
    additive.futureEnvelopeField = struct("preserved", true);
    additive.payload.extensions.futureMinor = struct("preserved", true);
    additivePath = fullfile(folder, "additive.mat");
    saveProject(additivePath, additive);
    labkit.ui.runtime.loadState(fig, additivePath);
    preservedPath = fullfile(folder, "preserved.mat");
    labkit.ui.runtime.saveState(fig, preservedPath);
    preserved = load(preservedPath, 'labkitProject');
    assert(isfield(preserved.labkitProject, 'futureEnvelopeField') && ...
        preserved.labkitProject.futureEnvelopeField.preserved && ...
        preserved.labkitProject.payload.extensions.futureMinor.preserved, ...
        'Unknown additive envelope fields should survive read-save.');

    legacy = stored.labkitProject;
    legacy.app.payloadVersion = 1;
    legacy.payload = legacyPayload();
    legacyPath = fullfile(folder, "legacy.mat");
    saveProject(legacyPath, legacy);
    labkit.ui.runtime.loadState(fig, legacyPath);
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    assert(runtime.state.project.parameters.count == 7 && ...
        runtime.state.project.parameters.migratedTo == 3 && ...
        ~isfield(runtime.state.project.parameters, 'defaultOnly') && ...
        runtime.document.dirty, ...
        'Ordered migrations should produce a complete payload without merging defaults.');

    snapshot = struct("app", struct("id", "runtime_v2_project_probe"), ...
        "state", struct("project", runtime.state.project));
    snapshot.state.project.parameters.count = 11;
    snapshotPath = fullfile(folder, "snapshot.mat");
    save(snapshotPath, 'snapshot');
    labkit.ui.runtime.loadState(fig, snapshotPath);
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    assert(runtime.state.project.parameters.count == 11 && ...
        runtime.document.dirty, ...
        'The named v1 snapshot adapter should remain read-only compatible.');
    labkit.ui.runtime.saveState(fig);
    upgraded = load(snapshotPath, 'labkitProject');
    assert(upgraded.labkitProject.app.payloadVersion == 3 && ...
        string(who('-file', snapshotPath)) == "labkitProject", ...
        ['Saving an imported old document should atomically replace it ' ...
        'with the current project format at the opened path.']);

    before = getappdata(fig, 'labkitUiAppRuntime');
    newer = stored.labkitProject;
    newer.formatVersion.major = 2;
    newerPath = fullfile(folder, "newer.mat");
    saveProject(newerPath, newer);
    assertThrows(@() labkit.ui.runtime.loadState(fig, newerPath), ...
        'labkit:ui:runtime:NewerProjectFormat');
    assertRuntimeUnchanged(fig, before, 'Newer major rejection must be atomic.');

    wrong = stored.labkitProject;
    wrong.app.id = "another_app";
    wrongPath = fullfile(folder, "wrong.mat");
    saveProject(wrongPath, wrong);
    assertThrows(@() labkit.ui.runtime.loadState(fig, wrongPath), ...
        'labkit:ui:runtime:WrongProjectApp');
    assertRuntimeUnchanged(fig, before, 'Wrong app rejection must be atomic.');

    malformed = stored.labkitProject;
    malformed.payload = rmfield(malformed.payload, 'extensions');
    malformedPath = fullfile(folder, "malformed.mat");
    saveProject(malformedPath, malformed);
    assertThrows(@() labkit.ui.runtime.loadState(fig, malformedPath), ...
        'labkit:ui:runtime:InvalidState');
    assertRuntimeUnchanged(fig, before, ...
        'Runtime project-shape rejection must precede App validation.');

    corruptSourcePath = fullfile(folder, "corrupt-input.dat");
    writeBytes(corruptSourcePath, uint8([13 37]));
    corruptSource = labkit.ui.runtime.sourceRecord( ...
        "requiredInput", "input data", corruptSourcePath, true);
    corrupt = stored.labkitProject;
    corrupt.payload.parameters.count = 13;
    corrupt.payload.inputs.sources = corruptSource;
    corrupt.sources = corruptSource;
    corruptPath = fullfile(folder, "corrupt-session.mat");
    saveProject(corruptPath, corrupt);
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    runtime.debug.reportException = @(appId, context, exception) ...
        setappdata(fig, 'projectLoadDiagnostic', struct( ...
        "appId", string(appId), "context", string(context), ...
        "exception", exception));
    setappdata(fig, 'labkitUiAppRuntime', runtime);
    beforeCorrupt = runtime;
    caught = [];
    try
        labkit.ui.runtime.loadState(fig, corruptPath);
    catch ME
        caught = ME;
    end
    assert(isa(caught, 'MException') && ...
        string(caught.identifier) == ...
        "labkit:ui:runtime:ProjectSessionRestoreFailed" && ...
        contains(string(caught.message), 'inputs.sources') && ...
        contains(string(caught.message), 'corrupt-input.dat'), ...
        ['An existing but undecodable source should identify its project ' ...
        'field and filename instead of appearing unresolved.']);
    diagnostic = getappdata(fig, 'projectLoadDiagnostic');
    assert(diagnostic.appId == "runtime_v2_project_probe" && ...
        contains(diagnostic.context, "corrupt-session.mat") && ...
        diagnostic.exception.identifier == ...
        "labkit:ui:runtime:ProjectSessionRestoreFailed", ...
        'Project session reconstruction failures should reach diagnostics.');
    assertRuntimeUnchanged(fig, beforeCorrupt, ...
        'Existing-source decode failure must leave live state unchanged.');

    unresolved = stored.labkitProject;
    missingSource = struct("id", "requiredInput", ...
        "required", true, "role", "input data", "reference", struct( ...
            "schemaVersion", 1, ...
            "relativePath", "missing/input.dat", ...
            "originalPath", "", "fileName", "input.dat"));
    unresolved.sources = missingSource;
    unresolved.payload.inputs.sources = missingSource;
    unresolvedPath = fullfile(folder, "unresolved.mat");
    saveProject(unresolvedPath, unresolved);

    replacementPath = fullfile(folder, "replacement.dat");
    writeBytes(replacementPath, uint8([8 9]));
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    runtime.request.choiceDialog = ...
        @(varargin) "Locate file";
    runtime.request.inputFileChooser = ...
        @(varargin) chooseKnownFile(replacementPath);
    setappdata(fig, 'labkitUiAppRuntime', runtime);
    labkit.ui.runtime.loadState(fig, unresolvedPath);
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    reference = runtime.state.project.inputs.sources.reference;
    assert(reference.originalPath == replacementPath && ...
        reference.relativePath == "replacement.dat" && ...
        runtime.state.session.cache.sourcePath == replacementPath && ...
        runtime.document.dirty, ...
        ['The default relinker should update the missing source before ' ...
        'session creation and mark the repaired project for saving.']);

    runtime.request.choiceDialog = @(varargin) "Cancel";
    runtime.request = rmfield(runtime.request, 'inputFileChooser');
    setappdata(fig, 'labkitUiAppRuntime', runtime);
    beforeCancel = runtime;
    assertThrows(@() labkit.ui.runtime.loadState(fig, unresolvedPath), ...
        'labkit:ui:runtime:ProjectLoadCancelled');
    assertRuntimeUnchanged(fig, beforeCancel, ...
        'Default relink cancellation must leave live state unchanged.');

    runtime.definition.project.RelinkSources = @cancelRelink;
    setappdata(fig, 'labkitUiAppRuntime', runtime);
    beforeCancel = runtime;
    assertThrows(@() labkit.ui.runtime.loadState(fig, unresolvedPath), ...
        'labkit:ui:runtime:ProjectLoadCancelled');
    assertRuntimeUnchanged(fig, beforeCancel, ...
        'Relink cancellation must leave live state unchanged.');

    protectedPath = fullfile(folder, "protected.mat");
    copyfile(currentPath, protectedPath);
    priorBytes = readBytes(protectedPath);
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    runtime.request.projectBeforeReplace = @failBeforeReplace;
    setappdata(fig, 'labkitUiAppRuntime', runtime);
    assertThrows(@() labkit.ui.runtime.saveState(fig, protectedPath), ...
        'projectProbe:WriteFailure');
    assert(isequal(readBytes(protectedPath), priorBytes), ...
        'Atomic write failure should preserve the prior project bytes.');

    delete(fig);
    clear cleanupFolder cleanupFigures cleanupMode;
end

function [request, dispatchArgs] = recoveryRequest(~, recoveryPath)
    request = struct("recoveryFile", recoveryPath, "autosave", false);
    dispatchArgs = {};
end

function def = definition()
    project = struct("Version", 3, "Create", @createProject, ...
        "Validate", @validateProject, "Migrate", @migrateProject, ...
        "CreateResume", @createResume, "ApplyResume", @applyResume);
    def = labkit.ui.runtime.define( ...
        "Id", "runtime_v2_project_probe", ...
        "Title", "Runtime V2 Project Probe", ...
        "Project", project, ...
        "CreateSession", @createSession, ...
        "Layout", @layout, ...
        "Actions", struct("increment", @increment, ...
            "export", @exportResult, "badExport", @badExport, ...
            "duplicateExport", @duplicateExport), ...
        "Present", @present, ...
        "Renderers", struct("probe", @renderProbe));
end

function project = migrateProject(project, fromVersion)
    switch fromVersion
        case 1
            project = migrateOneToTwo(project);
        case 2
            project = migrateTwoToThree(project);
        otherwise
            error('runtimeV2ProjectTest:UnsupportedProjectVersion', ...
                'No migration is defined from project version %d.', fromVersion);
    end
end

function project = createProject()
    project = buckets(struct("count", 0, "defaultOnly", true, ...
        "migratedTo", 3));
end

function project = legacyPayload()
    project = buckets(struct("count", 7));
    project.extensions.future = struct("keep", true);
end

function project = migrateOneToTwo(project)
    project.parameters.migratedTo = 2;
end

function project = migrateTwoToThree(project)
    project.parameters.migratedTo = 3;
end

function project = buckets(parameters)
    project = struct("inputs", struct(), "parameters", parameters, ...
        "annotations", struct(), "results", struct(), ...
        "extensions", struct());
end

function accepted = validateProject(project)
    accepted = isfield(project.parameters, 'count') && ...
        project.parameters.count >= 0;
end

function session = createSession(project)
    if project.parameters.count == 13
        error('projectProbe:CorruptSource', ...
            'Could not decode the selected source bytes.');
    end
    sourcePath = "";
    if isfield(project.inputs, 'sources') && ~isempty(project.inputs.sources)
        sourcePath = string( ...
            project.inputs.sources(1).reference.originalPath);
    end
    session = struct("selection", struct(), "workflow", struct(), ...
        "view", struct(), "cache", struct( ...
            "generation", project.parameters.count, ...
            "sourcePath", sourcePath, ...
            "resumedGeneration", 0));
end

function resume = createResume(~, project)
    resume = struct("generation", project.parameters.count);
end

function session = applyResume(session, resume, ~)
    if isstruct(resume) && isfield(resume, 'generation')
        session.cache.resumedGeneration = double(resume.generation);
    end
end

function tree = layout(callbacks)
    action = labkit.ui.layout.action("increment", "Increment", ...
        callbacks.increment);
    exportAction = labkit.ui.layout.action("export", "Export", ...
        callbacks.export);
    badExportAction = labkit.ui.layout.action("badExport", "Bad export", ...
        callbacks.badExport);
    duplicateExportAction = labkit.ui.layout.action( ...
        "duplicateExport", "Duplicate export", callbacks.duplicateExport);
    tree = labkit.ui.layout.workbench("projectProbe", ...
        "Runtime V2 Project Probe", ...
        "controlTabs", {labkit.ui.layout.tab("controls", "Controls", ...
            {labkit.ui.layout.section("actions", "Actions", ...
                {action, exportAction, badExportAction, ...
                duplicateExportAction})})}, ...
        "workspace", labkit.ui.layout.workspace("workspace", "Preview", ...
            {labkit.ui.layout.previewArea("preview", "Preview")}));
end

function state = increment(state, ~, ~)
    state.project.parameters.count = state.project.parameters.count + 1;
end

function state = exportResult(state, ~, services)
    folder = string(services.request.resultFolder);
    if ~isfolder(folder)
        mkdir(folder);
    end
    writeBytes(fullfile(folder, "data.bin"), uint8([1 2 3 4]));
    outputs = [ ...
        struct("Id", "data", "Role", "primary", "Path", "data.bin", ...
            "MediaType", "application/octet-stream", "Status", "success", ...
            "Message", ""), ...
        struct("Id", "missing", "Role", "secondary", "Path", "missing.csv", ...
            "MediaType", "text/csv", "Status", "success", "Message", "")];
    spec = struct("Outputs", outputs, ...
        "Parameters", state.project.parameters, ...
        "Summary", struct("count", state.project.parameters.count));
    [path, ~] = services.results.writeManifest(folder, spec);
    state.project.results.manifestPath = path;
end

function state = badExport(state, ~, services)
    outputs = struct("Id", "escape", "Role", "primary", ...
        "Path", "../outside.csv");
    services.results.writeManifest(services.request.resultFolder, ...
        struct("Outputs", outputs));
end

function state = duplicateExport(state, ~, services)
    outputs = [ ...
        struct("Id", "duplicate", "Role", "primary", ...
            "Path", "first.csv", "Status", "failed"), ...
        struct("Id", "duplicate", "Role", "secondary", ...
            "Path", "second.csv", "Status", "failed")];
    services.results.writeManifest(services.request.resultFolder, ...
        struct("Outputs", outputs));
end

function writeBytes(filepath, bytes)
    file = fopen(filepath, 'wb');
    cleanup = onCleanup(@() fclose(file));
    fwrite(file, bytes, 'uint8');
    clear cleanup;
end

function view = present(state)
    view = struct("previews", struct("preview", struct( ...
        "Renderer", "probe", "Model", state.project.parameters.count)));
end

function renderProbe(ax, count)
    cla(ax);
    plot(ax, [0 1], [count count + 1]);
end

function saveProject(filepath, value)
    labkitProject = value;
    save(filepath, 'labkitProject');
end

function bytes = readBytes(filepath)
    file = fopen(filepath, 'rb');
    cleanup = onCleanup(@() fclose(file));
    bytes = fread(file, inf, '*uint8');
    clear cleanup;
end

function assertRuntimeUnchanged(fig, expected, message)
    actual = getappdata(fig, 'labkitUiAppRuntime');
    assert(isequaln(actual.state, expected.state) && ...
        isequaln(actual.document, expected.document), message);
end

function failBeforeReplace(~, ~)
    error('projectProbe:WriteFailure', 'Expected write failure.');
end

function project = cancelRelink(~, ~, ~)
    project = [];
end

function [file, folder] = chooseKnownFile(filepath)
    [folder, name, extension] = fileparts(filepath);
    file = char(string(name) + string(extension));
    folder = char(folder);
end

function invoke(button)
    button.ButtonPushedFcn(button, struct());
end

function req = requirements()
    req = labkit.contract.requirements();
end

function info = versionInfo()
    info = struct("name", "runtime_v2_project_probe", ...
        "displayName", "Runtime V2 Project Probe", "family", "Test", ...
        "version", "1.0.0", "updated", "2026-07-14");
end

function assertThrows(callback, identifier)
    try
        callback();
    catch ME
        assert(strcmp(ME.identifier, identifier), ...
            'Expected %s but caught %s.', identifier, ME.identifier);
        return;
    end
    error('Expected an error with identifier %s.', identifier);
end
