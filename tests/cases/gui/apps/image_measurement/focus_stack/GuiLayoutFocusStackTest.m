classdef GuiLayoutFocusStackTest < matlab.uitest.TestCase
    %GUILAYOUTFOCUSSTACKTEST Verify focus stack GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function focus_stack_layout(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            fig = h.launchFigure('labkit_FocusStack_app', ...
                'Microscope Focus Stack Fusion');
            h.assertStandardWorkbenchLayout(fig);
            h.assertComponentCounts(fig, struct('Button', 8, 'CheckBox', 1, ...
                'DropDown', 1, 'Spinner', 3, 'ListBox', 1, 'Table', 1, ...
                'TextArea', 3, 'Axes', 2));
            h.assertButtonContract(fig, {'Open image folder', 'Choose files', ...
                'Clear', 'Run focus stack', 'Export fused PNG', ...
                'Export focus map PNG', 'Export summary CSV'});
            h.assertCheckboxContract(fig, {'Auto-register stack to middle image'});
            h.assertDropdownGroups(fig, h.dropdownGroup({'Balanced', ...
                'Crisp details', 'Smooth transitions', 'Noisy images'}, 1));
            h.assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});
            h.assertTableColumns(fig, {'Metric', 'Value'});
            h.assertAxesContract(fig, { ...
                h.axesSpec('Fused all-in-focus image', '', ''), ...
                h.axesSpec('Focus-depth index map', '', '')});

            h.closeAllFigures();
            [fig, debug] = labkit_FocusStack_app("debug");
            drawnow;
            assert(debug.enabled && debug.traceEnabled, ...
                'Focus Stack debug launch should return an enabled trace logger.');
            assertAnyTextAreaContains(h, fig, 'Focus stack debug trace enabled', ...
                'Focus Stack debug launch should mirror trace lines into the visible Log tab.');

            h.invokeDropdownValue(fig, 'Crisp details');
            lines = string(debug.getLog());
            assert(any(contains(lines, 'BEGIN ValueChangedFcn')), ...
                'Focus Stack debug mode should instrument declarative control callbacks.');
            assertAnyTextAreaContains(h, fig, 'BEGIN ValueChangedFcn', ...
                'Focus Stack debug mode should mirror instrumented callback traces into the visible Log tab.');
        end
    end
end
