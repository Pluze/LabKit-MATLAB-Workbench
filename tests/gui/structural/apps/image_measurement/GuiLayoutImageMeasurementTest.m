classdef GuiLayoutImageMeasurementTest < matlab.uitest.TestCase
    %GUILAYOUTIMAGEMEASUREMENTTEST Verify LabKit behavior through official MATLAB tests.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function test_gui_layout_image_measurement(testCase)
            setupLabKitTestPath();
            verify_gui_layout_image_measurement();
        end
    end
end

function verify_gui_layout_image_measurement()
%TEST_GUI_LAYOUT_IMAGE_MEASUREMENT Verify image-measurement GUI layout contracts.

    h = guiTestHelpers();
    h.assertUifigureAvailable();
    cleanup = onCleanup(@() h.closeAllFigures());

    checkCurvatureMeasurementLayout(h);
    checkFocusStackLayout(h);
    checkBatchImageCropLayout(h);
    checkImageEnhanceLayout(h);
    checkImageMatchLayout(h);
end

function checkCurvatureMeasurementLayout(h)
    fig = h.launchFigure('labkit_CurvatureMeasurement_app', 'Image Curvature Measurement');
    h.assertFigureMinimumSize(fig, 1420, 860);
    h.assertComponentCounts(fig, struct('Button', 10, 'CheckBox', 2, ...
        'DropDown', 3, 'Table', 1, 'TextArea', 3, 'Axes', 1));
    h.assertButtonContract(fig, {'Open image', 'Start curve edit', ...
        'Undo last point', 'Clear curve', ...
        'Measure reference pixels', 'Place scale bar', ...
        'Fit circle + curvature', 'Measure curve length', ...
        'Export result CSV', 'Export overlay PNG'});
    h.assertCheckboxContract(fig, {'Densify before circle fit', ...
        'Show dense fit points'});
    h.assertDropdownGroups(fig, [ ...
        h.dropdownGroup({'m', 'cm', 'mm', 'um', 'nm'}, 1), ...
        h.dropdownGroup({'Bottom center', 'Bottom left', 'Bottom right', ...
        'Top center', 'Top left', 'Top right'}, 1), ...
        h.dropdownGroup({'Black', 'White'}, 1)]);
    h.assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});
    h.assertTableColumns(fig, {'Metric', 'Value'});
    h.assertAxesContract(fig, {h.axesSpec('Image + Circle Fit', '', '')});

    h.closeAllFigures();
    [fig, debug] = labkit_CurvatureMeasurement_app("debug", struct());
    drawnow;
    assert(debug.enabled && debug.traceEnabled, ...
        'Curvature debug launch should return an enabled trace logger.');
    assertAnyTextAreaContains(h, fig, 'Curvature measurement debug trace enabled', ...
        'Curvature debug launch should mirror trace lines into the visible Log tab.');

    h.invokeCheckbox(fig, 'Show dense fit points', false);
    lines = string(debug.getLog());
    assert(any(contains(lines, 'BEGIN ValueChangedFcn') & contains(lines, 'Show dense fit points')), ...
        'Curvature debug mode should instrument GUI callbacks with control labels.');
    assert(any(contains(lines, 'ValueChangedFcn') & contains(lines, 'refreshImageOverlay')), ...
        'Curvature debug mode should include the original callback function name when available.');
    assertAnyTextAreaContains(h, fig, 'BEGIN ValueChangedFcn', ...
        'Curvature debug mode should mirror instrumented callback traces into the visible Log tab.');
end

function checkFocusStackLayout(h)
    fig = h.launchFigure('labkit_FocusStack_app', 'Microscope Focus Stack Fusion');
    h.assertFigureMinimumSize(fig, 1440, 860);
    h.assertComponentCounts(fig, struct('Button', 7, 'CheckBox', 1, ...
        'DropDown', 1, 'Spinner', 3, 'ListBox', 1, 'Table', 1, 'TextArea', 3, 'Axes', 2));
    h.assertButtonContract(fig, {'Open image folder', 'Choose files', 'Clear', ...
        'Run focus stack', 'Export fused PNG', 'Export focus map PNG', 'Export summary CSV'});
    h.assertCheckboxContract(fig, {'Auto-register stack to middle image'});
    h.assertDropdownGroups(fig, h.dropdownGroup({'Balanced', 'Crisp details', ...
        'Smooth transitions', 'Noisy images'}, 1));
    h.assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});
    h.assertTableColumns(fig, {'Metric', 'Value'});
    h.assertAxesContract(fig, { ...
        h.axesSpec('Fused all-in-focus image', '', ''), ...
        h.axesSpec('Focus-depth index map', '', '')});

    h.closeAllFigures();
    [fig, debug] = labkit_FocusStack_app("debug", struct());
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

function checkBatchImageCropLayout(h)
    fig = h.launchFigure('labkit_BatchImageCrop_app', 'Microscope Batch Image Crop');
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
    [fig, debug] = labkit_BatchImageCrop_app("debug", struct());
    drawnow;
    assert(debug.enabled && debug.traceEnabled, ...
        'Batch crop debug launch should return an enabled trace logger.');
    assertAnyTextAreaContains(h, fig, 'Batch image crop debug trace enabled', ...
        'Batch crop debug launch should mirror trace lines into the visible Log tab.');
end

function checkImageEnhanceLayout(h)
    fig = h.launchFigure('labkit_ImageEnhance_app', 'Paper Image Enhance');
    h.assertFigureMinimumSize(fig, 1460, 860);
    h.assertComponentCounts(fig, struct('Button', 7, 'DropDown', 3, ...
        'Spinner', 2, 'ListBox', 1, 'Table', 2, 'TextArea', 2, 'Axes', 1));
    h.assertButtonContract(fig, {'Choose files', 'Clear', ...
        'Apply tool', 'Undo history', 'Reset history', ...
        'Choose folder', 'Export enhanced images'});
    h.assertDropdownGroups(fig, [ ...
        h.dropdownGroup({'Enhanced', 'Original', 'Before | After'}, 1), ...
        h.dropdownGroup({'Brightness/contrast', 'Local contrast', 'Sharpen', ...
        'Hue/saturation', 'White balance'}, 1), ...
        h.dropdownGroup({'PNG', 'TIFF', 'JPEG'}, 1)]);
    h.assertTabTitles(fig, {'Library + Export', 'Tools + History', 'Log'});
    h.assertAnyTableColumns(fig, {'Metric', 'Value'});
    h.assertAnyTableColumns(fig, {'#', 'Step', 'Settings'});
    h.assertAxesContract(fig, {h.axesSpec('Enhanced Preview', '', '')});

    h.closeAllFigures();
    [fig, debug] = labkit_ImageEnhance_app("debug", struct());
    drawnow;
    assert(debug.enabled && debug.traceEnabled, ...
        'Image enhance debug launch should return an enabled trace logger.');
    assertAnyTextAreaContains(h, fig, 'Image enhance debug trace enabled', ...
        'Image enhance debug launch should mirror trace lines into the visible Log tab.');
end

function checkImageMatchLayout(h)
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
    [fig, debug] = labkit_ImageMatch_app("debug", struct());
    drawnow;
    assert(debug.enabled && debug.traceEnabled, ...
        'Image match debug launch should return an enabled trace logger.');
    assertAnyTextAreaContains(h, fig, 'Image match debug trace enabled', ...
        'Image match debug launch should mirror trace lines into the visible Log tab.');
end

function assertAnyTextAreaContains(h, fig, needle, message)
    textAreas = h.findControlsByClass(fig, 'TextArea');
    for k = 1:numel(textAreas)
        values = string(textAreas{k}.Value);
        if any(contains(values, needle))
            return;
        end
    end
    error(message);
end
