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
            h.assertComponentCounts(fig, struct('Button', 10, 'DropDown', 3, ...
                'Spinner', 2, 'CheckBox', 1, 'ListBox', 1, 'Table', 2, ...
                'TextArea', 2, 'Axes', 1));
            h.assertButtonContract(fig, {'Add images or folder', ...
                'Remove selected', 'Clear images', ...
                'Set white ROI', 'Apply tool', 'Undo history', 'Reset history', ...
                'Choose folder', 'Export enhanced images'});
            h.assertDropdownGroups(fig, [ ...
                h.dropdownGroup({'Enhanced', 'Original', 'Before | After'}, 1), ...
                h.dropdownGroup({'Brightness/contrast', 'Local contrast', ...
                'Sharpen', 'Hue/saturation', 'White balance', ...
                'White ROI calibration'}, 1), ...
                h.dropdownGroup({'PNG', 'TIFF', 'JPEG'}, 1)]);
            h.assertCheckboxContract(fig, {'Batch shared processing'});
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
            verifyPerImageHistoryRefresh(fig);
        end
    end
end

function verifyPerImageHistoryRefresh(fig)
    ui = getappdata(fig, 'labkitUiRegistry');
    item = image_enhance.state.emptyItem();
    item.path = "first.png";
    item.name = "first.png";
    item.image = ones(8, 8, 3) .* 0.5;
    item.steps = image_enhance.ops.makeStep('Brightness/contrast', 10, 0, 0);
    second = item;
    second.path = "second.png";
    second.name = "second.png";
    second.steps = image_enhance.ops.makeStep('Sharpen', 20, 1, 0);
    S = struct('items', [item; second], 'currentIndex', 1, ...
        'steps', repmat(image_enhance.state.emptyStep(), 0, 1), ...
        'batchMode', false, 'pendingDirty', false);

    ui.controls.historyTable.table.Data = image_enhance.view.historyTableData( ...
        image_enhance.state.activeSteps(S));
    firstData = ui.controls.historyTable.table.Data;
    S.currentIndex = 2;
    ui.controls.historyTable.table.Data = image_enhance.view.historyTableData( ...
        image_enhance.state.activeSteps(S));
    secondData = ui.controls.historyTable.table.Data;

    assert(contains(string(firstData{1, 2}), "Brightness"), ...
        'Per-image mode should show the first image history while first is selected.');
    assert(contains(string(secondData{1, 2}), "Sharpen"), ...
        'Per-image mode should refresh history when the selected image changes.');
end
