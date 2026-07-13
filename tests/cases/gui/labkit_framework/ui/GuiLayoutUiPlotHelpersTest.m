classdef GuiLayoutUiPlotHelpersTest < matlab.unittest.TestCase
    %GUILAYOUTUIPLOTHELPERSTEST Verify UI 5 plot helper contracts.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function test_gui_layout_ui_plot_helpers(testCase)
            setupLabKitTestPath();
            verify_gui_layout_ui_plot_helpers();
        end
    end
end

function verify_gui_layout_ui_plot_helpers()
%TEST_GUI_LAYOUT_UI_PLOT_HELPERS Verify reusable plot clearing, fitting, and coordinates.

    h = guiTestHelpers();
    h.assertUifigureAvailable();
    cleanup = onCleanup(@() h.closeAllFigures());

    layout = labkit.ui.layout.workbench('plotHelperProbe', 'Plot Helper Probe', ...
        'controlTabs', { ...
            labkit.ui.layout.tab('setup', 'Setup', { ...
                labkit.ui.layout.section('actions', 'Actions', { ...
                    labkit.ui.layout.action('noop', 'No-op', @noop)})})}, ...
        'workspace', labkit.ui.layout.workspace('workspace', 'Preview', { ...
            labkit.ui.layout.previewArea('preview', 'Preview', ...
                'layout', 'single', ...
                'axisIds', {'main'}, ...
                'axisTitles', {'Main Plot'})}));
    ui = labkit.ui.runtime.create(layout);

    ax = labkit.ui.plot.getAxes(ui, 'preview', 'main');
    assert(isequal(ax, ui.controls.preview.axesById.main), ...
        'plot.getAxes should resolve a semantic preview axes id.');

    mainLine = plot(ax, [0 10], [0 20], 'DisplayName', 'main');
    xline(ax, 1000, '--', 'far annotation');
    limits = labkit.ui.plot.fit(ax, mainLine, 'Padding', 0);
    assert(isequal(limits.x, [0 10]) && isequal(limits.y, [0 20]), ...
        'plot.fit should use caller-provided data handles instead of annotation handles.');

    ax.XLim = [1 100];
    ax.YLim = [-10 10];
    ax.XScale = 'log';
    ax.YDir = 'reverse';
    uv = labkit.ui.plot.dataToFraction(ax, [10 0]);
    xy = labkit.ui.plot.fractionToData(ax, uv);
    assert(max(abs(uv - [0.5 0.5])) < 1e-12 && ...
        max(abs(xy - [10 0])) < 1e-12, ...
        'Plot coordinate helpers should round-trip log and reversed axes.');

    offsetXY = labkit.ui.plot.offsetData(ax, [10 0], [0.1 -0.1]);
    offsetUV = labkit.ui.plot.dataToFraction(ax, offsetXY);
    assert(max(abs(offsetUV - [0.6 0.4])) < 1e-12, ...
        'plot.offsetData should apply visual axes-fraction offsets.');
    clampedXY = labkit.ui.plot.clampData(ax, [0.01 100], 'Padding', 0.1);
    clampedUV = labkit.ui.plot.dataToFraction(ax, clampedXY);
    assert(all(clampedUV >= 0.1 - eps) && all(clampedUV <= 0.9 + eps), ...
        'plot.clampData should keep labels inside the visible axes area.');

    labkit.ui.plot.message(ax, 'No data', 'Title', 'Empty');
    assert(isempty(findobj(ax, 'Type', 'line')) && isequal(ax.XLim, [0 1]) && ...
        isequal(ax.YLim, [0 1]) && strcmp(char(ax.Title.String), 'Empty'), ...
        'plot.message should clear the axes and install an empty-state viewport.');

    plot(ax, [1 2 3], [3 2 1], 'DisplayName', 'clear me');
    legend(ax, 'show');
    labkit.ui.plot.clear(ax, 'ResetScale', true);
    assert(isempty(ax.Children) && strcmp(ax.XLimMode, 'auto') && ...
        strcmp(ax.YLimMode, 'auto') && strcmp(ax.XScale, 'linear') && ...
        strcmp(ax.YScale, 'linear'), ...
        'plot.clear should remove graphics and restore automatic linear scaling.');

    function noop(varargin)
    end
end
