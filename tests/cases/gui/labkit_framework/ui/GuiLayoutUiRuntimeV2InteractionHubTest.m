classdef GuiLayoutUiRuntimeV2InteractionHubTest < matlab.unittest.TestCase
    %GUILAYOUTUIRUNTIMEV2INTERACTIONHUBTEST Verify figure-scoped V2 routing.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function hub_routes_targets_groups_and_drag_cleanup(testCase)
            setupLabKitTestPath();
            verifyHubMechanics();
        end

        function controlled_interactions_suppress_programmatic_events(testCase)
            setupLabKitTestPath();
            verifyControlledInteraction();
        end

        function controlled_rectangle_receives_hit_graphic(testCase)
            setupLabKitTestPath();
            verifyControlledRectangleHitRouting();
        end

        function paired_anchor_cell_payload_stays_one_semantic_event(testCase)
            setupLabKitTestPath();
            verifyPairedAnchorCellPayload();
        end

        function controlled_interval_routes_semantic_wheel_events(testCase)
            setupLabKitTestPath();
            verifyControlledInterval();
        end

        function controlled_region_selection_registers_transient_gesture(testCase)
            setupLabKitTestPath();
            verifyControlledRegionSelection();
        end

        function controlled_point_slots_preserve_fixed_indices(testCase)
            setupLabKitTestPath();
            verifyControlledPointSlots();
        end
    end
end

function verifyControlledRectangleHitRouting()
    h = guiTestHelpers();
    h.assertUifigureAvailable();
    oldMode = getenv('LABKIT_GUI_TEST_MODE');
    setenv('LABKIT_GUI_TEST_MODE', 'hidden');
    cleanupMode = onCleanup(@() setenv('LABKIT_GUI_TEST_MODE', oldMode));
    cleanupFigures = onCleanup(@() h.closeAllFigures());
    fig = labkit.ui.runtime.launch( ...
        @rectangleDefinition, @requirements, @versionInfo);
    h.waitForUiIdle(fig);
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    resource = interactionResource(runtime.resources, "cropRectangle");
    graphics = resource.editors{1}.graphics();
    box = graphics(find(arrayfun(@(item) isa(item, ...
        'matlab.graphics.primitive.Rectangle'), graphics), 1, 'first'));
    assert(~isempty(box), ...
        'A controlled rectangle should expose its editable box graphic.');

    ui = getappdata(fig, 'labkitUiRegistry');
    ax = ui.controls.image.primaryAxes;
    ax.XLim = [25 75];
    ax.YLim = [20 70];
    expectedView = [ax.XLim ax.YLim];
    runtime.interactionHub.dispatch("cropRectMoved", ...
        "cropRectangle", [30 30 40 40], "commit");
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    testCaseView = [ax.XLim ax.YLim];
    assert(isequal(testCaseView, expectedView) && ...
        isequal(runtime.state.project.annotations.cropRect, [30 30 40 40]), ...
        'An overlay edit should redraw its renderer without resetting zoom.');
    resource = interactionResource(runtime.resources, "cropRectangle");
    graphics = resource.editors{1}.graphics();
    box = graphics(find(arrayfun(@(item) isa(item, ...
        'matlab.graphics.primitive.Rectangle'), graphics), 1, 'first'));

    fig.WindowButtonDownFcn(fig, struct('HitObject', box));
    assert(runtime.interactionHub.isDragging(), ...
        'The figure hub must route the hit rectangle graphic into a drag session.');
    fig.WindowButtonUpFcn(fig, struct());
    assert(~runtime.interactionHub.isDragging(), ...
        'Releasing the pointer should finish the rectangle drag session.');
    delete(fig);
    clear cleanupFigures cleanupMode;
end

function verifyControlledPointSlots()
    h = guiTestHelpers();
    h.assertUifigureAvailable();
    oldMode = getenv('LABKIT_GUI_TEST_MODE');
    setenv('LABKIT_GUI_TEST_MODE', 'hidden');
    cleanupMode = onCleanup(@() setenv('LABKIT_GUI_TEST_MODE', oldMode));
    cleanupFigures = onCleanup(@() h.closeAllFigures());
    fig = labkit.ui.runtime.launch( ...
        @pointSlotsDefinition, @requirements, @versionInfo);
    h.waitForUiIdle(fig);
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    resource = interactionResource(runtime.resources, "slots");
    resource.editors{1}.insertPoint([30 40]);
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    value = runtime.state.project.annotations.slots;
    assert(isequal(value.points(2, :), [30 40]) && ...
        value.selectedIndex == 3 && value.changedIndex == 2 && ...
        value.reason == "place", ...
        'Point slots should fill the selected empty slot and retain its index.');
    delete(fig);
    clear cleanupFigures cleanupMode;
end

function verifyPairedAnchorCellPayload()
    h = guiTestHelpers();
    h.assertUifigureAvailable();
    oldMode = getenv('LABKIT_GUI_TEST_MODE');
    setenv('LABKIT_GUI_TEST_MODE', 'hidden');
    cleanupMode = onCleanup(@() setenv('LABKIT_GUI_TEST_MODE', oldMode));
    cleanupFigures = onCleanup(@() h.closeAllFigures());
    fig = labkit.ui.runtime.launch( ...
        @pairedDefinition, @requirements, @versionInfo);
    h.waitForUiIdle(fig);
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    resource = interactionResource(runtime.resources, "pointPairs");
    ui = getappdata(fig, 'labkitUiRegistry');
    leftAxes = ui.controls.pair.axesById.left;
    leftAxes.XLim = [0.5 100.5];
    leftAxes.YLim = [0.5 100.5];
    beforeZoom = [leftAxes.XLim leftAxes.YLim];
    runtime.interactionHub.routeWheel("pair.left", ...
        struct("VerticalScrollCount", -1, "Point", [50 50]));
    assert(~isequal(beforeZoom, [leftAxes.XLim leftAxes.YLim]), ...
        'A paired-anchor editor should route wheel input to shared image zoom.');
    resource.editors{1}.insertPoint([30 40]);
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    assert(size(runtime.state.project.annotations.referencePoints, 1) == 1 && ...
        isempty(runtime.state.project.annotations.movingPoints) && ...
        runtime.state.project.annotations.pairEditCount == 1, ...
        'The first paired-anchor edit should commit one scalar cell-valued event.');
    resource = interactionResource(runtime.resources, "pointPairs");
    resource.editors{2}.insertPoint([32 41]);
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    assert(size(runtime.state.project.annotations.referencePoints, 1) == 1 && ...
        size(runtime.state.project.annotations.movingPoints, 1) == 1 && ...
        runtime.state.project.annotations.pairEditCount == 2 && ...
        ~runtime.processing && isempty(runtime.queue), ...
        'A complete point pair should commit without expanding the event struct.');
    delete(fig);
    clear cleanupFigures cleanupMode;
end

function verifyControlledRegionSelection()
    h = guiTestHelpers();
    h.assertUifigureAvailable();
    oldMode = getenv('LABKIT_GUI_TEST_MODE');
    setenv('LABKIT_GUI_TEST_MODE', 'hidden');
    cleanupMode = onCleanup(@() setenv('LABKIT_GUI_TEST_MODE', oldMode));
    cleanupFigures = onCleanup(@() h.closeAllFigures());
    fig = labkit.ui.runtime.launch( ...
        @regionDefinition, @requirements, @versionInfo);
    h.waitForUiIdle(fig);
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    resource = interactionResource(runtime.resources, "region");
    assert(resource.spec.Kind == "regionSelection" && ...
        resource.spec.Event == "regionSelected" && ...
        resource.spec.BackgroundEvent == "pointSelected", ...
        'Region selection should normalize drag and click semantic events.');
    assert(isfield(resource.editors{1}, 'delete') && ...
        ~isfield(resource.editors{1}, 'setPosition'), ...
        'Transient region selection must not expose a durable ROI editor.');
    delete(fig);
    clear cleanupFigures cleanupMode;
end

function verifyControlledInterval()
    h = guiTestHelpers();
    h.assertUifigureAvailable();
    oldMode = getenv('LABKIT_GUI_TEST_MODE');
    setenv('LABKIT_GUI_TEST_MODE', 'hidden');
    cleanupMode = onCleanup(@() setenv('LABKIT_GUI_TEST_MODE', oldMode));
    cleanupFigures = onCleanup(@() h.closeAllFigures());
    fig = labkit.ui.runtime.launch( ...
        @intervalDefinition, @requirements, @versionInfo);
    h.waitForUiIdle(fig);
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    resource = interactionResource(runtime.resources, "timeRange");
    assert(resource.spec.Kind == "interval" && ...
        resource.spec.ScrollEvent == "windowScrolled", ...
        'Interval interactions should normalize their semantic wheel event.');
    runtime.interactionHub.routeWheel("image", ...
        struct("VerticalScrollCount", 1));
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    assert(runtime.state.project.annotations.scrollCount == 1, ...
        'A routed interval wheel gesture should enqueue one semantic event.');
    delete(fig);
    clear cleanupFigures cleanupMode;
end

function verifyHubMechanics()
    h = guiTestHelpers();
    h.assertUifigureAvailable();
    oldMode = getenv('LABKIT_GUI_TEST_MODE');
    setenv('LABKIT_GUI_TEST_MODE', 'hidden');
    cleanupMode = onCleanup(@() setenv('LABKIT_GUI_TEST_MODE', oldMode));
    cleanupFigures = onCleanup(@() h.closeAllFigures());
    fig = labkit.ui.runtime.launch( ...
        @hubDefinition, @requirements, @versionInfo);
    h.waitForUiIdle(fig);
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    ui = getappdata(fig, 'labkitUiRegistry');
    hub = runtime.interactionHub;
    assert(isequal(sort(hub.targetIds()), ...
        sort(["pair.left", "pair.right", "third"])), ...
        'Every preview axis should register one semantic hub target.');

    leftCount = 0;
    rightCount = 0;
    left = hub.adapter("pair.left", "paired");
    right = hub.adapter("pair.right", "paired");
    leftSession = left.createSession(struct( ...
        "onScroll", @(~, ~) incrementLeft()));
    rightSession = right.createSession(struct( ...
        "onScroll", @(~, ~) incrementRight()));
    leftSession.activate();
    assert(leftSession.isActive() && rightSession.isActive(), ...
        'Activating a grouped session should acquire every registered target.');
    event = struct("VerticalScrollCount", -1, "Point", [50 50]);
    hub.routeWheel("pair.left", event);
    hub.routeWheel("pair.right", event);
    assert(leftCount == 1 && rightCount == 1, ...
        'Wheel input should route directly to the hovered semantic target.');

    thirdAxes = ui.controls.third.primaryAxes;
    thirdAxes.XLim = [0 100];
    thirdAxes.YLim = [0 100];
    beforeLimits = [thirdAxes.XLim thirdAxes.YLim];
    hub.routeWheel("third", event);
    assert(~isequal(beforeLimits, [thirdAxes.XLim thirdAxes.YLim]), ...
        'An unclaimed preview target should retain hub-owned default zoom.');
    afterZoom = [thirdAxes.XLim thirdAxes.YLim];
    hub.routeWheel("", event);
    assert(isequal(afterZoom, [thirdAxes.XLim thirdAxes.YLim]), ...
        'Controls and empty figure areas must not consume preview zoom.');

    leftSession.deactivate();
    assert(~leftSession.isActive() && ~rightSession.isActive() && ...
        strlength(hub.activeGroup()) == 0, ...
        'Releasing one grouped session should release the group atomically.');

    leftSession.activate();
    stableMotion = fig.WindowButtonMotionFcn;
    leftSession.captureDrag(@failDrag, []);
    assertThrows(@() stableMotion(fig, struct()), 'hubProbe:DragFailure');
    assert(isequal(fig.WindowButtonMotionFcn, stableMotion), ...
        'Drag errors must preserve the hub-owned figure callback.');
    stableMotion(fig, struct());

    delete(thirdAxes);
    third = hub.adapter("third", "thirdGroup");
    thirdSession = third.createSession(struct());
    assertThrows(@() thirdSession.activate(), ...
        'labkit:ui:runtime:InvalidInteractionTarget');
    hub.delete();
    hub.delete();
    delete(fig);
    clear cleanupFigures cleanupMode;

    function incrementLeft()
        leftCount = leftCount + 1;
    end

    function incrementRight()
        rightCount = rightCount + 1;
    end
end

function verifyControlledInteraction()
    h = guiTestHelpers();
    h.assertUifigureAvailable();
    oldMode = getenv('LABKIT_GUI_TEST_MODE');
    setenv('LABKIT_GUI_TEST_MODE', 'hidden');
    cleanupMode = onCleanup(@() setenv('LABKIT_GUI_TEST_MODE', oldMode));
    cleanupFigures = onCleanup(@() h.closeAllFigures());
    fig = labkit.ui.runtime.launch( ...
        @controlledDefinition, @requirements, @versionInfo);
    h.waitForUiIdle(fig);
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    assert(runtime.state.project.annotations.editCount == 0, ...
        'Programmatic controlled-tool synchronization must not emit edits.');
    resource = interactionResource(runtime.resources, "editPoints");
    assert(isfield(resource.spec, 'BackgroundEvent') && ...
        strlength(resource.spec.BackgroundEvent) == 0, ...
        'Controlled interactions should normalize an optional semantic background event.');
    resource.editors{1}.insertPoint([30 30]);
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    assert(runtime.state.project.annotations.editCount == 1 && ...
        size(runtime.state.project.annotations.points, 1) == 3, ...
        'A user tool edit should enqueue exactly one configured semantic event.');
    ui = getappdata(fig, 'labkitUiRegistry');
    delete(ui.controls.image.primaryAxes);
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    assert(~hasInteractionResource(runtime.resources, "editPoints"), ...
        'Deleting a semantic target should dispose its controlled resource.');
    delete(fig);
    clear cleanupFigures cleanupMode;
end

function tf = hasInteractionResource(resources, id)
    tf = ~isempty(resources) && any([resources.scope] == "interaction" & ...
        [resources.id] == string(id));
end

function def = hubDefinition()
    def = definitionBase(@hubLayout, struct("noop", @noop), @hubPresentation);
end

function def = controlledDefinition()
    actions = struct("pointsEdited", @pointsEdited);
    def = definitionBase(@controlledLayout, actions, @controlledPresentation);
end

function def = pairedDefinition()
    actions = struct("pointPairsEdited", @pointPairsEdited);
    def = definitionBase(@hubLayout, actions, @pairedPresentation);
end

function def = rectangleDefinition()
    actions = struct("cropRectMoved", @cropRectMoved);
    def = definitionBase(@controlledLayout, actions, @rectanglePresentation);
end

function def = intervalDefinition()
    actions = struct("rangeEdited", @rangeEdited, ...
        "windowScrolled", @windowScrolled);
    def = definitionBase(@controlledLayout, actions, @intervalPresentation);
end

function def = regionDefinition()
    actions = struct("regionSelected", @noop, "pointSelected", @noop);
    def = definitionBase(@controlledLayout, actions, @regionPresentation);
end

function def = pointSlotsDefinition()
    actions = struct("slotsEdited", @slotsEdited);
    def = definitionBase(@controlledLayout, actions, @pointSlotsPresentation);
end

function def = definitionBase(layout, actions, presenter)
    project = struct("Version", 1, "Create", @createProject, ...
        "Validate", @(~) true, "Migrations", {{}});
    def = labkit.ui.runtime.define( ...
        "Id", "runtime_v2_hub_probe", ...
        "Title", "Runtime V2 Hub Probe", ...
        "Project", project, ...
        "CreateSession", @createSession, ...
        "Layout", layout, ...
        "Actions", actions, ...
        "Present", presenter, ...
        "Renderers", struct("resettingImage", @renderResettingImage));
end

function project = createProject()
    project = struct( ...
        "inputs", struct(), ...
        "parameters", struct(), ...
        "annotations", struct("points", [10 10; 20 20], ...
            "editCount", 0, "range", [NaN NaN], "scrollCount", 0, ...
            "referencePoints", zeros(0, 2), ...
            "movingPoints", zeros(0, 2), "pairEditCount", 0, ...
            "cropRect", [20 20 40 40], ...
            "slots", struct("points", [10 10; NaN NaN; NaN NaN], ...
            "selectedIndex", 2, "locked", false)), ...
        "results", struct(), ...
        "extensions", struct());
end

function session = createSession(~)
    session = struct("selection", struct(), "workflow", struct(), ...
        "view", struct(), "cache", struct());
end

function layout = hubLayout(~)
    pair = labkit.ui.layout.previewArea("pair", "Pair", ...
        "layout", "pair", "axisIds", {"left", "right"});
    third = labkit.ui.layout.previewArea("third", "Third");
    layout = workbenchLayout({pair, third});
end

function layout = controlledLayout(~)
    layout = workbenchLayout( ...
        {labkit.ui.layout.previewArea("image", "Image")});
end

function layout = workbenchLayout(previews)
    layout = labkit.ui.layout.workbench("hubProbe", ...
        "Runtime V2 Hub Probe", ...
        "controlTabs", {labkit.ui.layout.tab("controls", "Controls", {})}, ...
        "workspace", labkit.ui.layout.workspace( ...
            "workspace", "Previews", previews));
end

function view = hubPresentation(~)
    view = struct();
end

function view = controlledPresentation(state)
    view = struct();
    view.interactions.editPoints = struct( ...
        "Kind", "anchors", ...
        "Targets", "image", ...
        "Value", state.project.annotations.points, ...
        "Event", "pointsEdited", ...
        "ImageSize", [100 100], ...
        "ChangePolicy", "commit");
end

function view = pairedPresentation(state)
    view = struct();
    view.interactions.pointPairs = struct( ...
        "Kind", "pairedAnchors", ...
        "Targets", ["pair.left", "pair.right"], ...
        "Value", {{state.project.annotations.referencePoints, ...
            state.project.annotations.movingPoints}}, ...
        "Event", "pointPairsEdited", ...
        "ImageSize", {{[100 100], [100 100]}}, ...
        "ChangePolicy", "commit", ...
        "Options", struct("mode", "points"));
end

function view = rectanglePresentation(state)
    view = struct();
    view.previews.image = struct("Renderer", "resettingImage", ...
        "Model", state.project.annotations.cropRect);
    view.interactions.cropRectangle = struct( ...
        "Kind", "rectangle", "Targets", "image", ...
        "Value", state.project.annotations.cropRect, ...
        "Event", "cropRectMoved", "ImageSize", [100 100], ...
        "ChangePolicy", "commit", ...
        "Options", struct("fixedAspectRatio", true));
end

function renderResettingImage(ax, ~)
    cla(ax, 'reset');
    image(ax, zeros(100, 100, 3));
    axis(ax, 'image');
end

function view = intervalPresentation(state)
    view = struct();
    view.interactions.timeRange = struct( ...
        "Kind", "interval", "Targets", "image", ...
        "Value", state.project.annotations.range, ...
        "Event", "rangeEdited", "ScrollEvent", "windowScrolled");
end

function view = regionPresentation(~)
    view = struct();
    view.interactions.region = struct( ...
        "Kind", "regionSelection", "Targets", "image", ...
        "Value", [], "Event", "regionSelected", ...
        "BackgroundEvent", "pointSelected", ...
        "ImageSize", [100 100], "ChangePolicy", "commit");
end

function view = pointSlotsPresentation(state)
    view = struct();
    value = state.project.annotations.slots;
    if isfield(value, 'changedIndex')
        value = rmfield(value, {'changedIndex', 'reason'});
    end
    view.interactions.slots = struct( ...
        "Kind", "pointSlots", "Targets", "image", ...
        "Value", value, "Event", "slotsEdited", ...
        "ImageSize", [100 100], "ChangePolicy", "commit");
end

function state = pointsEdited(state, event, ~)
    state.project.annotations.points = event.value;
    state.project.annotations.editCount = ...
        state.project.annotations.editCount + 1;
end

function state = pointPairsEdited(state, event, ~)
    assert(iscell(event.value) && numel(event.value) == 2, ...
        'Paired-anchor events must retain one two-cell payload.');
    state.project.annotations.referencePoints = event.value{1};
    state.project.annotations.movingPoints = event.value{2};
    state.project.annotations.pairEditCount = ...
        state.project.annotations.pairEditCount + 1;
end

function state = cropRectMoved(state, event, ~)
    state.project.annotations.cropRect = event.value;
end

function state = rangeEdited(state, event, ~)
    state.project.annotations.range = event.value;
end

function state = windowScrolled(state, ~, ~)
    state.project.annotations.scrollCount = ...
        state.project.annotations.scrollCount + 1;
end

function state = slotsEdited(state, event, ~)
    state.project.annotations.slots = event.value;
end

function state = noop(state, ~, ~)
end

function resource = interactionResource(resources, id)
    index = find([resources.scope] == "interaction" & ...
        [resources.id] == string(id), 1, 'first');
    assert(~isempty(index), 'Expected controlled interaction resource.');
    resource = resources(index).value;
end

function req = requirements()
    req = labkit.contract.requirements();
end

function info = versionInfo()
    info = struct("name", "runtime_v2_hub_probe", ...
        "displayName", "Runtime V2 Hub Probe", "family", "Test", ...
        "version", "1.0.0", "updated", "2026-07-14");
end

function failDrag(~, ~)
    error('hubProbe:DragFailure', 'Expected drag callback failure.');
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
