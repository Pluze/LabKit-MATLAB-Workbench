classdef GuiLayoutDicPostprocessTest < matlab.uitest.TestCase
    %GUILAYOUTDICPOSTPROCESSTEST Verify DIC postprocess GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function dic_postprocess_layout(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            fig = h.launchFigure('labkit_DICPostprocess_app', 'DIC Strain Postprocess');
            h.assertStandardWorkbenchLayout(fig);
            h.assertComponentCounts(fig, struct('Button', 7, 'Table', 1, ...
                'TextArea', 2, 'Axes', 2));
            h.assertButtonContract(fig, {'Choose DIC MAT', ...
                'Choose reference', 'Choose mask', ...
                'Generate overlays + summary', ...
                'Save overlay PNGs', 'Export summary CSV'});
            h.assertTabTitles(fig, {'Files + Analysis', 'Summary + Results', 'Log'});
            h.assertTableColumns(fig, {'Metric','EXX','EYY'});
            h.assertAxesContract(fig, { ...
                h.axesSpec('EXX Overlay', '', ''), ...
                h.axesSpec('EYY Overlay', '', '')});
            assertFilesAnalysisSectionsFit(fig);
        end
    end
end

function assertFilesAnalysisSectionsFit(fig)
    ui = getappdata(fig, 'labkitUiRegistry');
    sectionIds = {'inputsSection', 'overlayOptions', 'imageOptions', ...
        'exportsSection'};
    layoutProps = {'height', 'minRows', 'minHeight', 'maxColumns', ...
        'rowSpacing', 'columnSpacing', 'padding', 'chrome', ...
        'columnWidth', 'rowHeight', 'position', 'leftWidth'};
    for k = 1:numel(sectionIds)
        props = ui.sections.(sectionIds{k}).spec.props;
        for iProp = 1:numel(layoutProps)
            assert(~isfield(props, layoutProps{iProp}), ...
                'DIC postprocess sections should use framework-owned layout.');
        end
    end
end
