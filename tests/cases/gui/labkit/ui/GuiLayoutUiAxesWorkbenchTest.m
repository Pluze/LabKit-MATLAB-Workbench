classdef GuiLayoutUiAxesWorkbenchTest < matlab.uitest.TestCase
    %GUILAYOUTUIAXESWORKBENCHTEST Verify UI 2.0 shell and axes behavior.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function test_gui_layout_ui_axes_workbench(testCase)
            setupLabKitTestPath();
            verify_gui_layout_ui_axes_workbench();
        end
    end
end

function verify_gui_layout_ui_axes_workbench()
%TEST_GUI_LAYOUT_UI_AXES_WORKBENCH Verify declarative workbench axes behavior.

    h = guiTestHelpers();
    h.assertUifigureAvailable();
    cleanup = onCleanup(@() h.closeAllFigures());

    spec = labkit.ui.spec.app('axesWorkbenchProbe', 'Axes Workbench Probe', ...
        'position', [40 30 1200 760], ...
        'leftWidth', 330, ...
        'controlTabs', { ...
            labkit.ui.spec.tab('setup', 'Setup', { ...
                labkit.ui.spec.section('inputs', 'Inputs', { ...
                    labkit.ui.spec.action('run', 'Run', @noop)})})}, ...
        'workspace', labkit.ui.spec.workspace('workspace', 'Preview', { ...
            labkit.ui.spec.previewArea('plotPreview', 'Plots', ...
                'layout', 'stack', ...
                'axisIds', {'plot', 'image'}, ...
                'axisTitles', {'Probe Plot', 'Image Probe'}, ...
                'xLabels', {'Probe X', ''}, ...
                'yLabels', {'Probe Y', ''})}));
    ui = labkit.ui.app.create(spec);

    h.assertFigureMinimumSize(ui.figure, 1200, 760);
    h.assertTabTitles(ui.figure, {'Setup', 'Preview', 'Inputs'});
    assert(isequal(ui.main.ColumnWidth, {330, 6, '1x'}), ...
        'UI 2.0 app builder should create the standard resizable workbench layout.');
    assert(strcmp(ui.rightPanel.Title, 'Preview'), ...
        'UI 2.0 app builder should preserve the workspace title.');

    plotAx = ui.controls.plotPreview.axesById.plot;
    plot(plotAx, 1:3, [1 4 2], 'DisplayName', 'probe');
    h.assertAxesPopoutEnabled(plotAx, ...
        'UI 2.0 preview axes should install the LabKit popout context action.');
    menuItem = findall(plotAx.ContextMenu, 'Type', 'uimenu', ...
        'Tag', 'labkitAxesPopoutMenu');
    h.invokeCallback(menuItem, 'MenuSelectedFcn');
    drawnow;
    popoutFig = findall(groot, 'Type', 'figure', 'Name', 'Probe Plot');
    assert(~isempty(popoutFig), 'Axes popout menu should create a standalone plot figure.');
    popoutCleaner = onCleanup(@() delete(popoutFig(1)));
    popoutAxes = findobj(popoutFig(1), 'Type', 'axes');
    assert(numel(popoutAxes) >= 1 && ~isempty(popoutAxes(1).Children), ...
        'Axes popout should copy plotted children.');
    assert(strcmp(popoutAxes(1).DataAspectRatioMode, 'auto') && ...
        strcmp(popoutAxes(1).PlotBoxAspectRatioMode, 'auto'), ...
        'Plot axes popout should keep copied plots freely resizable.');

    labkit.ui.view.drawImage(ui, 'plotPreview', ...
        zeros(12, 16, 3, 'uint8'), 'axis', 'image', 'title', 'Image Probe');
    imgAx = ui.controls.plotPreview.axesById.image;
    imageMenuItem = findall(imgAx.ContextMenu, 'Type', 'uimenu', ...
        'Tag', 'labkitAxesPopoutMenu');
    h.invokeCallback(imageMenuItem, 'MenuSelectedFcn');
    drawnow;
    imagePopoutFig = findall(groot, 'Type', 'figure', 'Name', 'Image Probe');
    assert(~isempty(imagePopoutFig), 'Image axes popout should create a standalone figure.');
    imageCleaner = onCleanup(@() delete(imagePopoutFig(1)));
    imagePopoutAxes = findobj(imagePopoutFig(1), 'Type', 'axes');
    assert(numel(imagePopoutAxes) >= 1, 'Image popout should create copied axes.');
    assert(strcmp(imagePopoutAxes(1).DataAspectRatioMode, 'manual'), ...
        'Image axes popout should preserve locked data aspect ratio.');

    function noop(varargin)
    end
end
