classdef GuiLayoutUiAppRuntimeTest < matlab.unittest.TestCase
    %GUILAYOUTUIAPPRUNTIMETEST Verify declarative app runtime contracts.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function test_gui_layout_ui_app_runtime(testCase)
            setupLabKitTestPath();
            verify_gui_layout_ui_app_runtime();
        end
    end
end

function verify_gui_layout_ui_app_runtime()
%TEST_GUI_LAYOUT_UI_APP_RUNTIME Verify state/action/render runtime flow.

    h = guiTestHelpers();
    h.assertUifigureAvailable();
    oldMode = getenv('LABKIT_GUI_TEST_MODE');
    setenv('LABKIT_GUI_TEST_MODE', 'hidden');
    cleanupMode = onCleanup(@() setenv('LABKIT_GUI_TEST_MODE', oldMode));
    cleanupFigures = onCleanup(@() h.closeAllFigures());
    debugLogFile = [tempname(tempdir) '.log'];
    cleanupLog = onCleanup(@() cleanupFile(debugLogFile));
    debugLines = {};
    debug = labkit.ui.debug.context('runtime_probe', ...
        struct('logFile', debugLogFile, 'logCallback', @captureDebugLine));

    actions = struct( ...
        'startup', @startupAction, ...
        'hydrate', @hydrateAction, ...
        'increment', @incrementAction, ...
        'applyPayload', @applyPayloadAction, ...
        'fail', @failingAction);
    def = labkit.ui.runtime.define( ...
        "Id", "runtime_probe", ...
        "Title", "Runtime Probe", ...
        "InitialState", @initialState, ...
        "Layout", @buildLayout, ...
        "Actions", actions, ...
        "Render", @renderState, ...
        "Snapshot", struct("Version", 1, ...
        "Serialize", @serializeState, ...
        "Deserialize", @deserializeState, ...
        "AfterLoad", @afterLoadState), ...
        "Startup", "startup", ...
        "Hydrate", "hydrate");

    fig = labkit.ui.runtime.run(def, struct("debug", debug));
    h.waitForUiIdle(fig);
    ui = getappdata(fig, 'labkitUiRegistry');
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    assert(runtime.state.count == 15, sprintf( ...
        'Startup and hydration phases should update app runtime state. Found count=%g.', ...
        runtime.state.count));
    assert(isequal(runtime.state.phaseOrder, ["startup", "hydrate"]), ...
        'Hydration should run after startup phases.');
    assert(contains(string(ui.controls.status.textArea.Value), "Count: 15"), ...
        'Startup and hydration phases should render prepared state.');
    phaseRecords = getappdata(fig, 'labkitUiAppRuntimePhases');
    assertPhaseRecord(phaseRecords, "startup", "startup", "completed");
    assertPhaseRecord(phaseRecords, "hydrate", "hydrate", "completed");

    button = ui.controls.increment.button;
    button.ButtonPushedFcn(button, struct());
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    assert(runtime.state.count == 16, ...
        'Generated semantic callback should dispatch to the app action.');
    assert(contains(string(ui.controls.status.textArea.Value), "Count: 16"), ...
        'Action dispatch should render the updated app state.');

    dispatch = getappdata(fig, 'runtimeProbeDispatch');
    dispatch("applyPayload", struct("amount", 4));
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    assert(runtime.state.count == 20, ...
        'Services dispatch should accept app payload structs.');
    assert(runtime.state.lastPayload == "4", ...
        'Services dispatch should deliver custom payload fields.');
    assertThrows(@() dispatch("fail", struct()), ...
        'runtimeProbe:ExpectedFailure', ...
        'Runtime dispatch should rethrow action failures.');
    phaseRecords = getappdata(fig, 'labkitUiAppRuntimePhases');
    assertPhaseRecord(phaseRecords, "programmatic", "fail", "failed");
    assert(any(contains(string(debugLines), ...
        'ERROR programmatic action fail failed')), ...
        'Runtime action failures should be reported through the debug context.');
    snapshotPath = string(tempname) + ".mat";
    setappdata(fig, 'labkitUiUtilityStateFile', snapshotPath);
    saveStateMenu = findall(fig, 'Tag', 'labkitUiUtilitySaveState');
    loadStateMenu = findall(fig, 'Tag', 'labkitUiUtilityLoadState');
    assert(~isempty(saveStateMenu) && ~isempty(loadStateMenu), ...
        'Workbench utility bar should expose state snapshot commands.');
    h.invokeCallback(saveStateMenu(1), 'MenuSelectedFcn');
    assert(isfile(snapshotPath), utilityFailureMessage(fig, ...
        'Utility Save State should write the configured snapshot file.'));
    savedVariables = string(who('-file', snapshotPath));
    assert(isequal(savedVariables, "snapshot"), ...
        'State snapshot file should contain exactly one snapshot variable.');
    saved = load(snapshotPath, "snapshot");
    assert(saved.snapshot.schema == "labkit.ui.runtime.snapshot.v1" && ...
        saved.snapshot.app.id == "runtime_probe" && ...
        saved.snapshot.app.snapshotVersion == "1", ...
        'Saved state snapshot should include schema, app id, and app snapshot version.');
    assert(~isfield(saved.snapshot.state, 'transient'), ...
        'Serialize hook should be able to remove transient runtime fields.');

    dispatch("increment", struct());
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    assert(runtime.state.count == 21, ...
        'Probe state should change before snapshot restore.');
    h.invokeCallback(loadStateMenu(1), 'MenuSelectedFcn');
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    assert(runtime.state.count == 20 && runtime.state.transient == "restored" && ...
        runtime.state.afterLoadCount == 1, ...
        'Snapshot load should restore saved state, run Deserialize, and run AfterLoad.');
    assert(contains(string(ui.controls.status.textArea.Value), "Count: 20"), ...
        'Snapshot load should rerender restored state.');

    badPath = string(tempname) + ".mat";
    snapshot = saved.snapshot;
    snapshot.app.id = "other_app";
    save(badPath, 'snapshot');
    assertThrows(@() labkit.ui.runtime.loadState(fig, badPath), ...
        'labkit:ui:runtime:IncompatibleSnapshot', ...
        'App id mismatch should fail before mutating state.');
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    assert(runtime.state.count == 20, ...
        'Failed snapshot load should leave current runtime state unchanged.');

    runtime.state.badHandle = fig;
    setappdata(fig, 'labkitUiAppRuntime', runtime);
    assertThrows(@() labkit.ui.runtime.saveState(fig, string(tempname) + ".mat"), ...
        'labkit:ui:runtime:UnserializableState', ...
        'Snapshot save should reject graphics handles with a path-specific diagnostic.');

    clear cleanupFigures cleanupMode cleanupLog;

    function captureDebugLine(line)
        debugLines{end+1, 1} = line;
    end
end

function state = initialState()
    state = struct('count', 0, 'lastPayload', "", ...
        'phaseOrder', strings(1, 0), 'transient', "runtime", ...
        'afterLoadCount', 0);
end

function layout = buildLayout(callbacks, ~)
    layout = labkit.ui.layout.workbench("runtimeProbe", "Runtime Probe", ...
        "controlTabs", {labkit.ui.layout.tab("main", "Main", { ...
        labkit.ui.layout.section("actions", "Actions", { ...
        labkit.ui.layout.action("increment", "Increment", callbacks.increment)})})}, ...
        "workspace", labkit.ui.layout.workspace("workspace", "Workspace", { ...
        labkit.ui.layout.statusPanel("status", "Status", "value", "Count: 0")}));
end

function state = startupAction(state, ~, ~)
    state.count = 10;
    state.phaseOrder(end + 1) = "startup";
end

function state = hydrateAction(state, ~, ~)
    state.count = state.count + 5;
    state.phaseOrder(end + 1) = "hydrate";
end

function state = incrementAction(state, ~, ~)
    state.count = state.count + 1;
end

function state = applyPayloadAction(state, payload, ~)
    state.count = state.count + payload.event.amount;
    state.lastPayload = string(payload.event.amount);
end

function state = failingAction(state, ~, ~)
    error('runtimeProbe:ExpectedFailure', 'Expected runtime failure.');
end

function renderState(state, ui, services)
    labkit.ui.control.setValue(ui, "status", "Count: " + state.count);
    setappdata(services.figure, 'runtimeProbeDispatch', services.dispatch);
end

function state = serializeState(state, services)
    setappdata(services.figure, 'runtimeProbeSerialized', true);
    state = rmfield(state, 'transient');
end

function state = deserializeState(state, services)
    setappdata(services.figure, 'runtimeProbeDeserialized', true);
    state.transient = "restored";
end

function state = afterLoadState(state, services)
    setappdata(services.figure, 'runtimeProbeAfterLoad', true);
    state.afterLoadCount = state.afterLoadCount + 1;
end

function assertPhaseRecord(records, kind, id, status)
    kinds = [records.kind];
    ids = [records.id];
    statuses = [records.status];
    elapsed = [records.elapsedSeconds];
    matched = kinds == kind & ids == id & statuses == status & elapsed >= 0;
    assert(any(matched), sprintf( ...
        'Expected runtime phase record kind=%s id=%s status=%s.', ...
        kind, id, status));
end

function assertThrows(fn, expectedIdentifier, label)
    try
        fn();
    catch ME
        assert(strcmp(ME.identifier, expectedIdentifier), ...
            '%s Expected %s but caught %s.', label, expectedIdentifier, ...
            ME.identifier);
        return;
    end
    error('%s Expected an error with identifier %s.', label, expectedIdentifier);
end

function cleanupFile(filepath)
    if exist(filepath, 'file') == 2
        delete(filepath);
    end
end

function message = utilityFailureMessage(fig, fallback)
    message = fallback;
    if isappdata(fig, 'labkitUiAlerts')
        alerts = getappdata(fig, 'labkitUiAlerts');
        message = sprintf('%s Last alert: %s', fallback, ...
            char(alerts(end).message));
    end
end
