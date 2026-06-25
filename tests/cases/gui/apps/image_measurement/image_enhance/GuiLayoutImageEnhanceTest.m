classdef GuiLayoutImageEnhanceTest < matlab.uitest.TestCase
    %GUILAYOUTIMAGEENHANCETEST Verify image enhance GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function image_enhance_layout(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            fig = h.launchFigure('labkit_ImageEnhance_app', 'Paper Image Enhance');
            h.assertStandardWorkbenchLayout(fig);
            h.assertComponentCounts(fig, struct('Button', 9, 'DropDown', 3, ...
                'Spinner', 2, 'ListBox', 1, 'Table', 2, 'TextArea', 2, 'Axes', 1));
            h.assertButtonContract(fig, {'Add images or folder', ...
                'Remove selected', 'Clear images', ...
                'Apply tool', 'Undo history', 'Reset history', ...
                'Choose folder', 'Export enhanced images'});
            h.assertDropdownGroups(fig, [ ...
                h.dropdownGroup({'Enhanced', 'Original', 'Before | After'}, 1), ...
                h.dropdownGroup({'Brightness/contrast', 'Local contrast', ...
                'Sharpen', 'Hue/saturation', 'White balance'}, 1), ...
                h.dropdownGroup({'PNG', 'TIFF', 'JPEG'}, 1)]);
            h.assertTabTitles(fig, {'Library + Export', 'Tools + History', 'Log'});
            h.assertAnyTableColumns(fig, {'Metric', 'Value'});
            h.assertAnyTableColumns(fig, {'#', 'Step', 'Settings'});
            h.assertAxesContract(fig, {h.axesSpec('Enhanced Preview', '', '')});

            h.closeAllFigures();
            [fig, debug] = labkit_ImageEnhance_app("debug");
            drawnow;
            assert(debug.enabled && debug.traceEnabled, ...
                'Image enhance debug launch should return an enabled trace logger.');
            assertAnyTextAreaContains(h, fig, 'Image enhance debug trace enabled', ...
                'Image enhance debug launch should mirror trace lines into the visible Log tab.');
        end
    end
end
