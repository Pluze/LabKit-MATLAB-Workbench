classdef GuiLayoutImageMatchTest < matlab.uitest.TestCase
    %GUILAYOUTIMAGEMATCHTEST Verify image match GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function image_match_layout(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            fig = h.launchFigure('labkit_ImageMatch_app', 'Paper Image Match');
            h.assertFigureMinimumSize(fig, 1460, 860);
            h.assertComponentCounts(fig, struct('Button', 7, 'DropDown', 4, ...
                'Spinner', 3, 'ListBox', 1, 'Table', 2, 'TextArea', 3, 'Axes', 1));
            h.assertButtonContract(fig, {'Choose files', 'Clear', ...
                'Apply match', 'Undo history', 'Reset history', ...
                'Choose folder', 'Export matched images'});
            h.assertDropdownGroups(fig, [ ...
                h.dropdownGroup({'Matched', 'Original', 'Before | After'}, 1), ...
                h.dropdownGroup({'Balanced', 'White balance', 'Tone only', ...
                'Lab style', 'Histogram'}, 1), ...
                h.dropdownGroup({'PNG', 'TIFF', 'JPEG'}, 1)]);
            h.assertTabTitles(fig, {'Library + Export', 'Match + History', 'Log'});
            h.assertAnyTableColumns(fig, {'Metric', 'Value'});
            h.assertAnyTableColumns(fig, {'#', 'Step', 'Settings', 'Ref'});
            h.assertAxesContract(fig, {h.axesSpec('Matched Preview', '', '')});

            h.closeAllFigures();
            [fig, debug] = labkit_ImageMatch_app("debug");
            drawnow;
            assert(debug.enabled && debug.traceEnabled, ...
                'Image match debug launch should return an enabled trace logger.');
            assertAnyTextAreaContains(h, fig, 'Image match debug trace enabled', ...
                'Image match debug launch should mirror trace lines into the visible Log tab.');
        end
    end
end
