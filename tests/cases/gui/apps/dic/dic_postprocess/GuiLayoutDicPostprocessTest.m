classdef GuiLayoutDicPostprocessTest < matlab.uitest.TestCase
    %GUILAYOUTDICPOSTPROCESSTEST Verify DIC postprocess GUI layout contracts.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function dic_postprocess_layout(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            fig = h.launchFigure('labkit_DICPostprocess_app', 'DIC Strain Postprocess');
            h.assertFigureMinimumSize(fig, 1450, 880);
            h.assertComponentCounts(fig, struct('Button', 6, 'Table', 1, ...
                'TextArea', 2, 'Axes', 2));
            h.assertButtonContract(fig, {'Open DIC MAT', 'Open reference image', ...
                'Open mask image', 'Generate overlays + summary', ...
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
    for k = 1:numel(sectionIds)
        props = ui.sections.(sectionIds{k}).spec.props;
        assert(~isfield(props, 'height'), ...
            'DIC postprocess left sections should use default automatic height estimation.');
    end
end
