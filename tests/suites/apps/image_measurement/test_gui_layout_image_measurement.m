function test_gui_layout_image_measurement()
%TEST_GUI_LAYOUT_IMAGE_MEASUREMENT Verify image-measurement GUI layout contracts.

    h = guiTestHelpers();
    h.assertUifigureAvailable();
    cleanup = onCleanup(@() h.closeAllFigures()); %#ok<NASGU>

    fig = h.launchFigure('labkit_CurvatureMeasurement_app', 'Image Curvature Measurement');
    h.assertFigureMinimumSize(fig, 1420, 860);
    h.assertComponentCounts(fig, struct('Button', 8, 'CheckBox', 2, ...
        'DropDown', 1, 'Table', 1, 'TextArea', 3, 'Axes', 1));
    h.assertButtonContract(fig, {'Open image', 'Start curve edit', ...
        'Undo last point', 'Clear curve', ...
        'Measure scale bar', 'Fit circle + curvature', ...
        'Export result CSV', 'Export overlay PNG'});
    h.assertCheckboxContract(fig, {'Densify before circle fit', ...
        'Show dense fit points'});
    h.assertDropdownGroups(fig, h.dropdownGroup({'Curve', 'Straight lines'}, 1));
    h.assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});
    h.assertTableColumns(fig, {'Metric', 'Value'});
    h.assertAxesContract(fig, {h.axesSpec('Image + Circle Fit', '', '')});
end
