classdef GuiLayoutChronoOverlayTest < matlab.uitest.TestCase
    %GUILAYOUTCHRONOOVERLAYTEST Verify chrono overlay GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function chrono_overlay_layout(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            fig = h.launchFigure('labkit_ChronoOverlay_app', ...
                'Gamry Multi-DTA Plot Export GUI');
            h.assertFigureMinimumSize(fig, 1400, 850);
            h.assertComponentCounts(fig, struct('Button', 5, 'CheckBox', 2, ...
                'DropDown', 1, 'ListBox', 1, 'TextArea', 2, 'Axes', 2));
            h.assertButtonContract(fig, {'Open DTA file(s)', ...
                'Open folder recursively', 'Remove selected', ...
                'Clear all', 'Export curves CSV'});
            h.assertCheckboxContract(fig, {'Show file-name legend', 'Show grid'});
            h.assertDropdownGroups(fig, h.dropdownGroup( ...
                {'Time (s)', 'Time (ms)', 'Sample #'}, 1));
            h.assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});
            h.assertAxesContract(fig, { ...
                h.axesSpec('Voltage', 'Time (s)', 'Vf (V)'), ...
                h.axesSpec('Current', 'Time (s)', 'Im (A)')});
            h.assertDropdownCallbacksPresent(fig);
            h.invokeDropdownValue(fig, 'Time (ms)');
            h.invokeCheckbox(fig, 'Show file-name legend', false);
            h.invokeButton(fig, 'Clear all');
        end
    end
end
