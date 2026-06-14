classdef GuiLayoutBatchCropTest < matlab.uitest.TestCase
    %GUILAYOUTBATCHCROPTEST Verify batch crop GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function batch_crop_layout(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            fig = h.launchFigure('labkit_BatchImageCrop_app', ...
                'Microscope Batch Image Crop');
            h.assertFigureMinimumSize(fig, 1440, 860);
            h.assertComponentCounts(fig, struct('Button', 7, 'DropDown', 2, ...
                'Spinner', 5, 'ListBox', 1, 'Table', 1, 'TextArea', 2, 'Axes', 1));
            h.assertButtonContract(fig, {'Open image files', 'Clear images', ...
                'Previous image', 'Next image', 'Use canvas center', ...
                'Choose export folder', 'Export cropped images'});
            h.assertDropdownGroups(fig, [ ...
                h.dropdownGroup({'Black', 'White'}, 1), ...
                h.dropdownGroup({'PNG', 'TIFF', 'JPEG'}, 1)]);
            h.assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});
            h.assertTableColumns(fig, {'Metric', 'Value'});
            h.assertAxesContract(fig, {h.axesSpec('Rotated preview + fixed crop', '', '')});

            h.closeAllFigures();
            [fig, debug] = labkit_BatchImageCrop_app("debug");
            drawnow;
            assert(debug.enabled && debug.traceEnabled, ...
                'Batch crop debug launch should return an enabled trace logger.');
            assertAnyTextAreaContains(h, fig, 'Batch image crop debug trace enabled', ...
                'Batch crop debug launch should mirror trace lines into the visible Log tab.');
        end
    end
end
