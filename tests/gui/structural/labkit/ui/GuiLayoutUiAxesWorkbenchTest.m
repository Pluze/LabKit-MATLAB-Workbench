classdef GuiLayoutUiAxesWorkbenchTest < matlab.uitest.TestCase
    %GUILAYOUTUIAXESWORKBENCHTEST Verify LabKit behavior through official MATLAB tests.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function test_gui_layout_ui_axes_workbench(testCase)
            setupLabKitTestPath();
            verify_gui_layout_ui_axes_workbench();
        end
    end
end

function verify_gui_layout_ui_axes_workbench()
%TEST_GUI_LAYOUT_UI_AXES_WORKBENCH Verify axes, shell, and plot-control helpers.

    h = guiTestHelpers();
    h.assertUifigureAvailable();
    cleanup = onCleanup(@() h.closeAllFigures());

    checkCreateAxesHelper(h);
    checkCreateAppShellHelper(h);
end

function checkCreateAxesHelper(h)
    fig = uifigure('Visible', 'off', 'Name', 'labkit_create_axes_probe');
    cleaner = onCleanup(@() delete(fig));
    grid = uigridlayout(fig, [2 1]);

    ax = labkit.ui.view.axes(grid, 2, 'Probe Title', 'Probe X', 'Probe Y');
    plot(ax, 1:3, [1 4 2], 'DisplayName', 'probe');
    labkit.ui.view.draw(ax, 'popout');
    assert(ax.Layout.Row == 2, 'Axes helper should set the requested layout row.');
    assert(strcmp(char(ax.Title.String), 'Probe Title'), 'Axes helper should preserve the title.');
    assert(strcmp(char(ax.XLabel.String), 'Probe X'), 'Axes helper should preserve the x label.');
    assert(strcmp(char(ax.YLabel.String), 'Probe Y'), 'Axes helper should preserve the y label.');
    h.assertAxesPopoutEnabled(ax, 'Axes helper should install the LabKit popout context action.');

    menuItem = findall(ax.ContextMenu, 'Type', 'uimenu', 'Tag', 'labkitAxesPopoutMenu');
    h.invokeCallback(menuItem, 'MenuSelectedFcn');
    drawnow;
    popoutFig = findall(groot, 'Type', 'figure', 'Name', 'Probe Title');
    assert(~isempty(popoutFig), 'Axes popout menu should create a standalone figure.');
    popoutFig = popoutFig(1);
    popoutCleaner = onCleanup(@() delete(popoutFig));
    popoutAxes = findobj(popoutFig, 'Type', 'axes');
    assert(numel(popoutAxes) >= 1, 'Axes popout should create an editable figure axes.');
    assert(strcmp(char(popoutAxes(1).Title.String), 'Probe Title'), ...
        'Axes popout should preserve the source title.');
    assert(~isempty(popoutAxes(1).Children), ...
        'Axes popout should copy plotted children.');
    assert(strcmp(popoutAxes(1).DataAspectRatioMode, 'auto') && ...
        strcmp(popoutAxes(1).PlotBoxAspectRatioMode, 'auto'), ...
        'Axes popout should leave the copied plot with freely adjustable aspect ratio.');
    h.assertAxesChildrenUsePopoutMenu(ax, ...
        'Axes helper should attach the popout menu to plotted child objects.');

    imgAx = labkit.ui.view.axes(grid, 1, 'Image Probe', '', '');
    hImage = labkit.ui.view.draw(imgAx, 'image', zeros(12, 16, 3, 'uint8'), 'Image Probe');
    assert(strcmp(char(imgAx.Title.String), 'Image Probe'), ...
        'Image axes helper should preserve the supplied title.');
    assert(isequal(hImage.ContextMenu, imgAx.ContextMenu), ...
        'Image axes helper should attach the popout menu to the image object.');
end

function checkCreateAppShellHelper(h)
    opts = struct();
    opts.rightTitle = 'Preview';
    opts.rightGridSize = [2 1];
    opts.rightRowHeight = {'1x', 'fit'};
    opts.rightRowSpacing = 7;
    ui = labkit.ui.app.createShell(struct( ...
        'title', 'labkit_create_app_shell_probe', ...
        'position', [40 30 1200 760], ...
        'leftWidth', 330, ...
        'options', opts));
    cleaner = onCleanup(@() delete(ui.fig));

    assert(isequal(ui.main.ColumnWidth, {330, 6, '1x'}), ...
        'App shell helper should create the standard resizable left/separator/right layout.');
    h.assertTabTitles(ui.fig, {'Files + Analysis', 'Summary + Results', 'Log'});
    h.assertScrollablePanel(ui.filesAnalysisScrollPanel, 'Files + Analysis tab');
    h.assertScrollableGrid(ui.filesAnalysisGrid, 'Files + Analysis grid');
    assert(numel(ui.filesAnalysisResizeHandles) == 2, ...
        'Standard Files + Analysis tab should expose two row-resize handles.');
    assert(numel(ui.summaryResultsResizeHandles) == 1, ...
        'Standard Summary + Results tab should expose one row-resize handle.');
    assert(isequal(ui.filesAnalysisGrid.UserData.LabKitLogicalRowMap, [1 3 5]), ...
        'App shell should keep standard app rows mapped behind the shell.');
    resizeHandle = ui.filesAnalysisResizeHandles(1);
    h.assertCallbackPresent(resizeHandle, 'ButtonDownFcn', 'row-resize handle');
    h.invokeCallback(resizeHandle, 'ButtonDownFcn');
    assert(~isempty(ui.fig.WindowButtonMotionFcn) && ~isempty(ui.fig.WindowButtonUpFcn), ...
        'Shell row-resize drag should install temporary figure motion callbacks.');
    h.invokeCallback(ui.fig, 'WindowButtonUpFcn');
    assert(isempty(ui.fig.WindowButtonMotionFcn) && isempty(ui.fig.WindowButtonUpFcn), ...
        'Shell row-resize drag should clear temporary figure callbacks after release.');
    assert(strcmp(ui.rightPanel.Title, 'Preview'), ...
        'App shell helper should preserve the requested right panel title.');
    assert(isequal(ui.rightGrid.RowHeight, {'1x', 'fit'}), ...
        'App shell helper should preserve custom right-grid rows.');

    customOpts = struct();
    customOpts.rightTitle = 'Custom';
    customOpts.tabs = labkit.ui.app.tab( ...
        'probe', 'Probe Controls', [2 1], {'fit', '1x'});
    custom = labkit.ui.app.createShell(struct( ...
        'title', 'labkit_custom_tab_app_shell_probe', ...
        'position', [40 30 1200 760], ...
        'leftWidth', 330, ...
        'options', customOpts));
    cleaner3 = onCleanup(@() delete(custom.fig));
    h.assertTabTitles(custom.fig, {'Probe Controls'});
    h.assertScrollablePanel(custom.probeScrollPanel, 'Probe Controls tab');
    h.assertScrollableGrid(custom.probeGrid, 'Probe Controls grid');
    assert(isequal(custom.probeGrid.RowHeight, {'fit', 6, '1x'}), ...
        'App shell helper should preserve custom tab specs.');
    assert(numel(custom.probeResizeHandles) == 1, ...
        'Custom multi-row tabs should create default row-resize handles.');

    fixedOpts = struct();
    fixedOpts.rightTitle = 'Fixed';
    fixedOpts.tabs = labkit.ui.app.tab( ...
        'fixed', 'Fixed Controls', [2 1], {'fit', '1x'}, ...
        struct('resize', 'none'));
    fixed = labkit.ui.app.createShell(struct( ...
        'title', 'labkit_fixed_tab_app_shell_probe', ...
        'position', [40 30 1200 760], ...
        'leftWidth', 330, ...
        'options', fixedOpts));
    cleaner4 = onCleanup(@() delete(fixed.fig));
    assert(h.sameStringCell(fixed.fixedGrid.RowHeight, {'fit', '1x'}), ...
        'Explicit fixed custom tabs should preserve row specs.');
    assert(isempty(fixed.fixedResizeHandles), ...
        'Custom tabs with resize none should not create resize handles.');

end
