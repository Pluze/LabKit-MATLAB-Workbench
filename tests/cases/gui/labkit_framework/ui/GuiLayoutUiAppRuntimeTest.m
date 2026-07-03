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

    actions = struct( ...
        'startup', @startupAction, ...
        'increment', @incrementAction);
    def = labkit.ui.app.define( ...
        "Id", "runtime_probe", ...
        "Title", "Runtime Probe", ...
        "InitialState", @initialState, ...
        "Spec", @buildSpec, ...
        "Actions", actions, ...
        "Render", @renderState, ...
        "Startup", "startup");

    fig = labkit.ui.app.run(def);
    ui = getappdata(fig, 'labkitUiRegistry');
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    assert(runtime.state.count == 10, ...
        'Startup phase should update app runtime state.');
    assert(contains(string(ui.controls.status.textArea.Value), "Count: 10"), ...
        'Startup phase should render prepared state.');

    button = ui.controls.increment.button;
    button.ButtonPushedFcn(button, struct());
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    assert(runtime.state.count == 11, ...
        'Generated semantic callback should dispatch to the app action.');
    assert(contains(string(ui.controls.status.textArea.Value), "Count: 11"), ...
        'Action dispatch should render the updated app state.');

    clear cleanupFigures cleanupMode;
end

function state = initialState()
    state = struct('count', 0);
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
end

function state = incrementAction(state, ~, ~)
    state.count = state.count + 1;
end

function renderState(state, ui, ~)
    labkit.ui.view.setValue(ui, "status", "Count: " + state.count);
end
