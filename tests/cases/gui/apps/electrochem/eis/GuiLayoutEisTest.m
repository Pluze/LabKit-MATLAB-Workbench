classdef GuiLayoutEisTest < matlab.uitest.TestCase
    %GUILAYOUTEISTEST Verify EIS GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function eis_layout(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            fig = h.launchFigure('labkit_EIS_app', 'Gamry EIS Multi-DTA Plot GUI');
            h.assertFigureMinimumSize(fig, 1400, 850);
            h.assertComponentCounts(fig, struct('Button', 5, 'CheckBox', 5, ...
                'DropDown', 2, 'ListBox', 1, 'TextArea', 3, 'Axes', 1));
            h.assertButtonContract(fig, {'Open DTA file(s)', ...
                'Open folder recursively', 'Remove selected', ...
                'Clear all', 'Export current plot CSV'});
            h.assertCheckboxContract(fig, {'Show markers', 'Log X', 'Log Y', ...
                'Legend', 'Grid'});
            h.assertDropdownGroups(fig, h.dropdownGroup(eisAxisItems(), 2));
            h.assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});
            h.assertAxesContract(fig, { ...
                h.axesSpec('EIS Overlay', 'Zreal (ohm)', '-Zimag (ohm)')});
            h.assertDropdownCallbacksPresent(fig);
            h.invokeDropdownValue(fig, 'Freq (Hz)');
            h.invokeCheckbox(fig, 'Log X', true);
            h.invokeButton(fig, 'Clear all');
        end
    end
end

function items = eisAxisItems()
    items = {'Freq (Hz)', 'log10(Freq)', 'Time (s)', 'Point #', ...
        'Zreal (ohm)', 'Zimag (ohm)', '-Zimag (ohm)', 'Zmod (ohm)', ...
        'Zphz (deg)', 'Idc (A)', 'Vdc (V)'};
end
