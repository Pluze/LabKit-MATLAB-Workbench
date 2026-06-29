classdef GuiLayoutCurvatureTest < matlab.uitest.TestCase
    %GUILAYOUTCURVATURETEST Verify curvature measurement GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function curvature_layout(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            fig = h.launchFigure('labkit_CurvatureMeasurement_app', ...
                'Image Curvature Measurement');
            h.assertStandardWorkbenchLayout(fig);
            h.assertButtonContract(fig, {'Choose image', 'Start curve edit', ...
                'Undo last point', 'Clear curve', 'Measure reference pixels', ...
                'Place scale bar', 'Fit circle + curvature', ...
                'Measure curve length', 'Export result CSV', 'Export overlay PNG'});
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
            assertScaleBarPanelSpansControlTab(fig);

            h.closeAllFigures();
            [fig, debug] = labkit_CurvatureMeasurement_app("debug");
            drawnow;
            assert(debug.enabled && debug.traceEnabled, ...
                'Curvature debug launch should return an enabled trace logger.');
            assertAnyTextAreaContains(h, fig, ...
                'Curvature measurement debug trace enabled', ...
                'Curvature debug launch should mirror trace lines into the visible Log tab.');

            h.invokeCheckbox(fig, 'Show dense fit points', false);
            lines = string(debug.getLog());
            assert(any(contains(lines, 'BEGIN ValueChangedFcn') & ...
                contains(lines, 'Show dense fit points')), ...
                'Curvature debug mode should instrument GUI callbacks with control labels.');
            assert(any(contains(lines, 'ValueChangedFcn') & ...
                contains(lines, 'refreshImageOverlay')), ...
                'Curvature debug mode should include the original callback function name.');
            assertAnyTextAreaContains(h, fig, 'BEGIN ValueChangedFcn', ...
                'Curvature debug mode should mirror instrumented callback traces into the visible Log tab.');
        end
    end
end

function assertScaleBarPanelSpansControlTab(fig)
    hosts = findall(fig, 'Type', 'uipanel', 'Tag', 'LabKitToolPanel_scaleBarHost');
    assert(numel(hosts) >= 1, 'Curvature app should include a scale-bar tool host.');
    hostLayout = hosts(1).Layout;
    assert(isprop(hostLayout, 'Column') && isequal(hostLayout.Column, [1 2]), ...
        'Scale-bar tool host should span the full two-column control section.');

    scalePanels = findall(fig, 'Type', 'uipanel', 'Title', 'Scale Bar');
    assert(numel(scalePanels) >= 1, 'Curvature app should include a Scale Bar panel.');
    for k = 1:numel(scalePanels)
        if scalePanels(k).Parent == hosts(1).Children(1)
            assert(scalePanels(k).Position(3) > 250, ...
                'Scale Bar panel width should not be clipped inside the tool host.');
            return;
        end
    end
    error('Scale Bar panel should be mounted inside the semantic tool host.');
end
