classdef GuiLayoutVtResistanceTest < matlab.uitest.TestCase
    %GUILAYOUTVTRESISTANCETEST Verify VT resistance GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function vt_resistance_layout(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            fig = h.launchFigure('labkit_VTResistance_app', ...
                'Gamry VT Steady Resistance GUI');
            h.assertStandardWorkbenchLayout(fig);
            h.assertButtonContract(fig, {'Add DTA files', 'Remove selected', ...
                'Clear all', 'Export results CSV', ...
                'Re-analyze file', 'Refresh plots', 'Swap top / bottom', ...
                'Reset axes'});
            h.assertCheckboxContract(fig, {'Show markers', 'Shade windows', 'Grid'});
            h.assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});
            h.assertDropdownGroups(fig, [ ...
                h.dropdownGroup({'Metadata first, then auto', 'Metadata only', ...
                'Auto from Im only'}, 1), ...
                h.dropdownGroup({'Full pulse median', 'Center 60% median'}, 1), ...
                h.dropdownGroup({'Baseline-corrected dV/I', 'Raw Vf/I'}, 1), ...
                h.dropdownGroup({'Time (s)', 'Sample #'}, 2), ...
                h.dropdownGroup({'VT: Vf vs time', 'IT: Im vs time'}, 2)]);
            h.assertTableColumns(fig, {'File','Ic(A)','Ia(A)','Vc_ss(V)', ...
                'Va_ss(V)','R_cath(ohm)','R_anod(ohm)','R_avg(ohm)', ...
                'Detection'});
            h.assertAxesContract(fig, { ...
                h.axesSpec('Top Plot', '', ''), ...
                h.axesSpec('Bottom Plot', '', '')});
            h.assertDropdownCallbacksPresent(fig);
            h.invokeButton(fig, 'Refresh plots');
            h.invokeButton(fig, 'Reset axes');
            h.invokeButton(fig, 'Clear all');
            verifyVtPlotAxisClearRemovesAnnotations();
        end
    end
end

function verifyVtPlotAxisClearRemovesAnnotations()
    fig = uifigure('Visible', 'off');
    cleaner = onCleanup(@() delete(fig));
    ax = uiaxes(fig);
    plot(ax, 1:3, [1 4 2], 'HandleVisibility', 'off');
    hold(ax, 'on');
    xline(ax, 2, ':', 'marker');
    text(ax, 2, 3, 'annotation', 'HandleVisibility', 'off');
    vt_resistance.view.clearPlotAxis(ax);
    assert(isempty(ax.Children), ...
        'VT plot refresh should remove previous hidden markers and annotations.');
    assert(strcmp(ax.XLimMode, 'auto') && strcmp(ax.YLimMode, 'auto'), ...
        'VT plot refresh should restore automatic axis limits.');
end
