classdef GuiLayoutUiImageAxesRuntimeTest < matlab.uitest.TestCase
    %GUILAYOUTUIIMAGEAXESRUNTIMETEST Verify LabKit behavior through official MATLAB tests.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function test_gui_layout_ui_image_axes_runtime(testCase)
            setupLabKitTestPath();
            verify_gui_layout_ui_image_axes_runtime();
        end
    end
end

function verify_gui_layout_ui_image_axes_runtime()
%TEST_GUI_LAYOUT_UI_IMAGE_AXES_RUNTIME Verify managed image axes interaction runtime.

    h = guiTestHelpers();
    h.assertUifigureAvailable();
    cleanup = onCleanup(@() h.closeAllFigures());

    fig = uifigure('Visible', 'off', 'Name', 'labkit_image_axes_runtime_probe');
    cleaner = onCleanup(@() delete(fig));
    ax = uiaxes(fig);
    bg = imagesc(ax, rand(30, 40));
    defaultScrollCalls = 0;
    interactionEvents = {};
    traceMessages = {};

    runtime = labkit.ui.tool.createRuntime(ax, ...
        struct('figure', fig, ...
        'defaultScrollFcn', @onDefaultScroll, ...
        'scrollScope', 'figure', ...
        'onInteractionChanged', @onInteractionChanged, ...
        'onTrace', @captureTrace));
    assert(~isempty(fig.WindowScrollWheelFcn), ...
        'Image axes runtime should install a managed default scroll callback.');
    fig.WindowScrollWheelFcn(fig, struct());
    assert(defaultScrollCalls == 1, ...
        'Runtime default scroll wrapper should call the registered app callback.');

    sessionScroll = @(~,~) setappdata(fig, 'sessionScrollCalled', true);
    session = runtime.createSession(struct( ...
        'name', 'scrollProbe', ...
        'onPointerDown', @(~,~) setappdata(fig, 'pointerCalled', true), ...
        'onScroll', sessionScroll, ...
        'installScrollWheel', true, ...
        'scrollScope', 'figure'));
    session.setBackground(bg);
    session.activate();
    assert(~isempty(fig.WindowScrollWheelFcn), ...
        'Active scroll-owning sessions should temporarily replace the default scroll callback.');
    fig.WindowScrollWheelFcn(fig, struct());
    assert(isappdata(fig, 'sessionScrollCalled'), ...
        'Active scroll-owning sessions should receive managed scroll events.');
    assert(strcmp(bg.HitTest, 'on') && strcmp(bg.PickableParts, 'visible'), ...
        'Active sessions should make their background pointer-interactive.');
    session.deactivate();
    assert(~isempty(fig.WindowScrollWheelFcn), ...
        'Deactivated sessions should restore the managed runtime default scroll callback.');
    assert(strcmp(bg.HitTest, 'off') && strcmp(bg.PickableParts, 'none'), ...
        'Deactivated sessions should release background hit testing.');
    assert(isequal(interactionEvents(1, :), {true, 'scrollProbe'}) && ...
        isequal(interactionEvents(2, :), {false, 'scrollProbe'}), ...
        'Runtime interaction-change callback should receive active state and session name.');
    traceText = string(traceMessages);
    assert(any(contains(traceText, 'imageAxesRuntime: activate session scrollProbe')) && ...
        any(contains(traceText, 'imageAxesRuntime: deactivate session scrollProbe active=1')), ...
        'Image axes runtime should trace session activation and deactivation.');

    session.activate();
    peer = runtime.createSession(struct( ...
        'name', 'peerProbe', ...
        'onPointerDown', @(~,~) setappdata(fig, 'peerPointerCalled', true), ...
        'installScrollWheel', false));
    assert(~peer.activateIfAvailable(), ...
        'Non-forcing activation should not steal axes ownership from an active peer session.');
    assert(session.isActive() && strcmp(runtime.activeInteractionName(), "scrollProbe"), ...
        'Runtime should keep the original active session when a peer activation is skipped.');
    session.deactivate();
    assert(peer.canActivate() && peer.activateIfAvailable() && peer.isActive(), ...
        'Non-forcing activation should succeed once the runtime is idle.');
    assert(strcmp(runtime.activeInteractionName(), "peerProbe"), ...
        'Runtime should expose the current active interaction name.');
    peer.deactivate();

    keepScroll = runtime.createSession(struct( ...
        'name', 'defaultScrollProbe', ...
        'onPointerDown', @(~,~) setappdata(fig, 'pointerCalled', true), ...
        'installScrollWheel', false));
    keepScroll.setBackground(bg);
    keepScroll.activate();
    assert(~isempty(fig.WindowScrollWheelFcn), ...
        'Sessions with installScrollWheel=false should keep the runtime default scroll callback active.');
    keepScroll.deactivate();
    assert(~isempty(fig.WindowScrollWheelFcn), ...
        'Default scroll callback should remain installed after non-scroll session cleanup.');

    runtime.delete();

    fig2 = uifigure('Visible', 'off', 'Name', 'labkit_image_axes_runtime_target_probe');
    cleanup2 = onCleanup(@() delete(fig2));
    ax2 = uiaxes(fig2);
    targetCalls = 0;
    runtime2 = labkit.ui.tool.createRuntime(ax2, struct( ...
        'figure', fig2, ...
        'defaultScrollFcn', @onTargetDefaultScroll, ...
        'defaultScrollTargets', []));
    fig2.WindowScrollWheelFcn(fig2, struct());
    assert(targetCalls == 0, ...
        'Runtime target-gated default scroll should not dispatch when no targets are declared.');
    runtime2.setScrollScope('figure');
    fig2.WindowScrollWheelFcn(fig2, struct());
    assert(targetCalls == 1, ...
        'Runtime figure-scope scroll should dispatch without target hit testing.');
    runtime2.delete();

    fig3 = uifigure('Visible', 'off', 'Name', 'labkit_image_axes_runtime_fallback_probe');
    cleanup3 = onCleanup(@() delete(fig3));
    ax3 = uiaxes(fig3);
    fallbackCalls = 0;
    fig3.WindowScrollWheelFcn = @onFallbackScroll;
    runtime3 = labkit.ui.tool.createRuntime(ax3, struct( ...
        'figure', fig3, ...
        'defaultScrollFcn', @onTargetDefaultScroll, ...
        'defaultScrollTargets', []));
    fig3.WindowScrollWheelFcn(fig3, struct());
    assert(fallbackCalls == 1, ...
        'Runtime target misses should pass scroll events back to the pre-runtime fallback.');
    runtime3.delete();

    function onInteractionChanged(active, name)
        interactionEvents(end+1, :) = {active, char(name)};
    end

    function captureTrace(message)
        traceMessages{end+1, 1} = message;
    end

    function onDefaultScroll(~, ~)
        defaultScrollCalls = defaultScrollCalls + 1;
    end

    function onTargetDefaultScroll(~, ~)
        targetCalls = targetCalls + 1;
    end

    function onFallbackScroll(~, ~)
        fallbackCalls = fallbackCalls + 1;
    end
end
