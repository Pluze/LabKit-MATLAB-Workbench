classdef GuiLayoutUiRuntimeV2ProjectTest < matlab.unittest.TestCase
    %GUILAYOUTUIRUNTIMEV2PROJECTTEST Verify durable V2 project documents.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function project_roundtrip_migration_and_failures_are_atomic(testCase)
            setupLabKitTestPath();
            verifyProjectDocuments();
        end
    end
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

    sourcePath = fullfile(folder, "portable-input.dat");
    writeBytes(sourcePath, uint8([5 6 7]));
    portable = stored.labkitProject;
    source = struct("id", "requiredInput", "required", true, ...
        "role", "input", "reference", struct( ...
            "schemaVersion", 1, "relativePath", "portable-input.dat", ...
            "originalPath", fullfile(folder, "old", "portable-input.dat"), ...
            "fileName", "portable-input.dat"));
    portable.sources = source;
    portable.payload.inputs.sources = source;
    portablePath = fullfile(folder, "portable.mat");
    saveProject(portablePath, portable);
    labkit.ui.runtime.loadState(fig, portablePath);
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    assert(runtime.state.project.inputs.sources.reference.originalPath == ...
        sourcePath && runtime.state.session.cache.sourcePath == sourcePath, ...
        ['Resolved portable sources must update the durable project before ' ...
        'the fresh session is constructed.']);

    invoke(ui.controls.increment.button);
    assert(getappdata(fig, 'labkitUiAppRuntime').state.project.parameters.count == 2);
    labkit.ui.runtime.loadState(fig, currentPath);
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    assert(runtime.state.project.parameters.count == 1 && ...
        runtime.state.session.cache.generation == 1 && ...
        runtime.state.session.cache.resumedGeneration == 1 && ...
        ~runtime.document.dirty, ...
        'Open should replace project, construct a fresh session, and mark clean.');

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
        ~isfield(runtime.state.project.parameters, 'defaultOnly'), ...
        'Ordered migrations should produce a complete payload without merging defaults.');

    snapshot = struct("app", struct("id", "runtime_v2_project_probe"), ...
        "state", struct("project", runtime.state.project));
    snapshot.state.project.parameters.count = 11;
    snapshotPath = fullfile(folder, "snapshot.mat");
    save(snapshotPath, 'snapshot');
    labkit.ui.runtime.loadState(fig, snapshotPath);
    assert(getappdata(fig, 'labkitUiAppRuntime').state.project.parameters.count == 11, ...
        'The named v1 snapshot adapter should remain read-only compatible.');

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

    unresolved = stored.labkitProject;
    unresolved.sources = struct("id", "requiredInput", ...
        "required", true, "reference", struct( ...
            "relativePath", "missing/input.dat", ...
            "originalPath", "", "fileName", "input.dat"));
    unresolvedPath = fullfile(folder, "unresolved.mat");
    saveProject(unresolvedPath, unresolved);
    runtime = getappdata(fig, 'labkitUiAppRuntime');
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
        "Validate", @validateProject, ...
        "Migrations", {{@migrateOneToTwo, @migrateTwoToThree}}, ...
        "CreateResume", @createResume, "ApplyResume", @applyResume);
    def = labkit.ui.runtime.define( ...
        "Id", "runtime_v2_project_probe", ...
        "Title", "Runtime V2 Project Probe", ...
        "Project", project, ...
        "CreateSession", @createSession, ...
        "Layout", @layout, ...
        "Actions", struct("increment", @increment, ...
            "export", @exportResult, "badExport", @badExport), ...
        "Present", @present);
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
    tree = labkit.ui.layout.workbench("projectProbe", ...
        "Runtime V2 Project Probe", ...
        "controlTabs", {labkit.ui.layout.tab("controls", "Controls", ...
            {labkit.ui.layout.section("actions", "Actions", ...
                {action, exportAction, badExportAction})})}, ...
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

function writeBytes(filepath, bytes)
    file = fopen(filepath, 'wb');
    cleanup = onCleanup(@() fclose(file));
    fwrite(file, bytes, 'uint8');
    clear cleanup;
end

function view = present(~)
    view = struct();
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
