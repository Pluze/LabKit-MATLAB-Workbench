classdef FigureStudioSourceAxesTest < matlab.unittest.TestCase
    %FIGURESTUDIOSOURCEAXESTEST Verify Figure Studio source axes import prep.

    methods (Test, TestTags = {'Unit'})
        function copyToPreviewNormalizesLayoutBeforeStyling(testCase)
            setupLabKitTestPath();
            cleanup = onCleanup(@() closeAllTestFigures());

            sourceFig = figure('Visible', 'off', 'Color', 'w');
            sourceAx = axes('Parent', sourceFig);
            plot(sourceAx, linspace(0, 30, 200), sin(linspace(0, 30, 200)));
            xlabel(sourceAx, 'Time');
            ylabel(sourceAx, 'Signal');
            pbaspect(sourceAx, [1 0.1 1]);
            daspect(sourceAx, [10 1 1]);

            previewFig = figure('Visible', 'off', 'Color', 'w');
            previewAx = axes('Parent', previewFig);
            figure_studio.sourceAxes.copyToPreview(sourceAx, previewAx);

            testCase.verifyEqual(string(previewAx.PlotBoxAspectRatioMode), "auto", ...
                "Imported FIG layout constraints should not be carried into the Studio preview.");
            testCase.verifyEqual(string(previewAx.DataAspectRatioMode), "auto", ...
                "Imported FIG data aspect constraints should be normalized before Studio styling.");
            testCase.verifyEqual(numel(previewAx.Children), numel(sourceAx.Children), ...
                "Imported FIG data graphics should still be copied into the preview.");
        end

        function figFileImportUsesDisplayedAxesRatioForCanvas(testCase)
            setupLabKitTestPath();
            cleanup = onCleanup(@() closeAllTestFigures());

            sourceFig = figure('Visible', 'off', 'Color', 'w', ...
                'Units', 'pixels', 'Position', [100 100 720 540]);
            sourceAx = axes('Parent', sourceFig, 'Units', 'normalized', ...
                'Position', [0.13 0.34 0.775 0.58]);
            plot(sourceAx, 1:4, [1 3 2 4]);
            pbaspect(sourceAx, [1 0.1 1]);

            style = figure_studio.sourceAxes.sourceStyle(sourceAx, ...
                "PreserveAspect", false);
            ratio = double(style.canvasWidth) / double(style.canvasHeight);

            testCase.verifyGreaterThan(ratio, 1.2, ...
                "FIG default canvas should follow displayed axes geometry.");
            testCase.verifyLessThan(ratio, 3, ...
                "FIG default canvas should not inherit extreme cached plot-box ratios.");
        end

        function axesHandoffCanPreserveSourcePlotBoxRatio(testCase)
            setupLabKitTestPath();
            cleanup = onCleanup(@() closeAllTestFigures());

            sourceFig = figure('Visible', 'off', 'Color', 'w');
            sourceAx = axes('Parent', sourceFig);
            plot(sourceAx, 1:4, [1 3 2 4]);
            pbaspect(sourceAx, [2 1 1]);

            style = figure_studio.sourceAxes.sourceStyle(sourceAx);
            ratio = double(style.canvasWidth) / double(style.canvasHeight);

            testCase.verifyLessThan(abs(ratio - 2), 0.02, ...
                "Axes handoff should still preserve explicit source plot-box ratios.");
        end
    end
end

function closeAllTestFigures()
    delete(findall(groot, 'Type', 'figure'));
end
