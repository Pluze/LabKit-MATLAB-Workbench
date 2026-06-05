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
    cleanup = onCleanup(@() h.closeAllFigures()); %#ok<NASGU>

    checkCurvatureMeasurementLayout(h);
    checkFocusStackLayout(h);
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
    h.assertComponentCounts(fig, struct('Button', 6, 'CheckBox', 1, ...
        'DropDown', 1, 'Spinner', 3, 'ListBox', 1, 'Table', 1, 'TextArea', 3, 'Axes', 2));
    h.assertButtonContract(fig, {'Open image folder', 'Open image files', ...
        'Run focus stack', 'Export fused PNG', 'Export focus map PNG', 'Export summary CSV'});
    h.assertCheckboxContract(fig, {'Auto-register stack to middle image'});
    h.assertDropdownGroups(fig, h.dropdownGroup({'Balanced', 'Crisp details', ...
        'Smooth transitions', 'Noisy images'}, 1));
    h.assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});
    h.assertTableColumns(fig, {'Metric', 'Value'});
    h.assertAxesContract(fig, { ...
        h.axesSpec('Fused all-in-focus image', '', ''), ...
        h.axesSpec('Focus-depth index map', '', '')});
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
