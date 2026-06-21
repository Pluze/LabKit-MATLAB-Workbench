classdef GuiLayoutCscTest < matlab.uitest.TestCase
    %GUILAYOUTCSCTEST Verify CSC GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function csc_layout(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            fig = h.launchFigure('labkit_CSC_app', 'Gamry DTA GUI (literature CSC)');
            h.assertStandardWorkbenchLayout(fig);
            h.assertComponentCounts(fig, struct('Button', 10, 'CheckBox', 6, ...
                'DropDown', 6, 'ListBox', 1, 'TextArea', 1, 'Axes', 2));
            h.assertButtonContract(fig, {'Open DTA file(s)', ...
                'Open folder recursively', 'Clear all', 'Reload selected', ...
                'Auto CV + CT', 'Swap Top/Bottom', 'Compare Q / CSC', ...
                'Refresh Plots', 'Clear Both'});
            h.assertCheckboxContract(fig, {'Grid', 'Hold', 'Show Trim'});
            h.assertDropdownGroups(fig, [ ...
                h.dropdownGroup({'(none)'}, 5), ...
                h.dropdownGroup({'Full', 'Cathodic', 'Anodic'}, 1)]);
            h.assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});
            h.assertAxesContract(fig, { ...
                h.axesSpec('Top Plot', 'X', 'Y'), ...
                h.axesSpec('Bottom Plot', 'X', 'Y')});
            h.assertDropdownCallbacksPresent(fig);
            h.invokeDropdownValue(fig, 'Cathodic');
            h.invokeButton(fig, 'Refresh Plots');
            h.invokeButton(fig, 'Clear Both');
        end
    end
end
