classdef GuiLayoutUiAppRuntimeTest < matlab.uitest.TestCase
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
    debug = labkit.ui.diag.createContext('runtime_probe', ...
        struct('logFile', debugLogFile, 'logCallback', @captureDebugLine));

    actions = struct( ...
        'startup', @startupAction, ...
        'hydrate', @hydrateAction, ...
        'increment', @incrementAction, ...
        'applyPayload', @applyPayloadAction, ...
        'fail', @failingAction);
    def = labkit.ui.app.define( ...
        "Id", "runtime_probe", ...
        "Title", "Runtime Probe", ...
        "InitialState", @initialState, ...
        "Spec", @buildSpec, ...
        "Actions", actions, ...
        "Render", @renderState, ...
        "Startup", "startup", ...
        "Hydrate", "hydrate");

    fig = labkit.ui.app.run(def, struct("debug", debug));
    ui = getappdata(fig, 'labkitUiRegistry');
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    assert(runtime.state.count == 15, ...
        'Startup and hydration phases should update app runtime state.');
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

    clear cleanupFigures cleanupMode cleanupLog;

    function captureDebugLine(line)
        debugLines{end+1, 1} = line;
    end
end

function state = initialState()
    state = struct('count', 0, 'lastPayload', "", ...
        'phaseOrder', strings(1, 0));
end

function spec = buildSpec(callbacks, ~)
    spec = labkit.ui.spec.app("runtimeProbe", "Runtime Probe", ...
        "controlTabs", {labkit.ui.spec.tab("main", "Main", { ...
        labkit.ui.spec.section("actions", "Actions", { ...
        labkit.ui.spec.action("increment", "Increment", callbacks.increment)})})}, ...
        "workspace", labkit.ui.spec.workspace("workspace", "Workspace", { ...
        labkit.ui.spec.statusPanel("status", "Status", "value", "Count: 0")}));
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
    labkit.ui.view.setValue(ui, "status", "Count: " + state.count);
    setappdata(services.figure, 'runtimeProbeDispatch', services.dispatch);
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
