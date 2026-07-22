classdef FigureStudioSourceAxesTest < matlab.unittest.TestCase
    %FIGURESTUDIOSOURCEAXESTEST Verify Figure Studio source axes import prep.

    methods (Test, TestTags = {'Unit'})
        function copyToPreviewPreservesNativeAxesGeometry(testCase)
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

            testCase.verifyEqual(string(previewAx.PlotBoxAspectRatioMode), "manual", ...
                "Native source geometry should not be replaced by export canvas sizing.");
            testCase.verifyEqual(string(previewAx.DataAspectRatioMode), "manual", ...
                "Native source data geometry should remain available in the preview.");
            testCase.verifyEqual(numel(previewAx.Children), numel(sourceAx.Children), ...
                "Imported FIG data graphics should still be copied into the preview.");
        end

        function copyToPreviewPreservesImageOverlayStack(testCase)
            setupLabKitTestPath();
            cleanup = onCleanup(@() closeAllTestFigures());

            sourceFig = figure('Visible', 'off', 'Color', 'w');
            sourceAx = axes('Parent', sourceFig);
            image(sourceAx, 'CData', uint8(80 .* ones(12, 16, 3)), ...
                'XData', [0 1], 'YData', [0 1]);
            hold(sourceAx, 'on');
            line(sourceAx, [0.1 0.9], [0.2 0.8], ...
                'Color', [1 0 0], 'LineWidth', 3);
            text(sourceAx, 0.5, 0.6, 'overlay', ...
                'HorizontalAlignment', 'center');
            hold(sourceAx, 'off');

            previewFig = figure('Visible', 'off', 'Color', 'w');
            previewAx = axes('Parent', previewFig);
            figure_studio.sourceAxes.copyToPreview(sourceAx, previewAx);

            testCase.verifyEqual(childTypes(previewAx), childTypes(sourceAx), ...
                "Preview stacking must match the source front-to-back order.");
            testCase.verifyEqual(childTypes(previewAx), ...
                ["text"; "line"; "image"], ...
                "The opaque image must remain behind its visible overlays.");
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
            testCase.verifyEmpty(style.axesPosition, ...
                "FIG default must preserve source axes placement rather than applying the LabKit frame.");
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

        function limitControlsUseExactFiftyPercentDataEnvelope(testCase)
            setupLabKitTestPath();
            plotData = struct( ...
                "objects", struct( ...
                    "type", "line", "x", [2; 6], "y", [-1; 3]), ...
                "axes", struct("xLim", [2 6], "yLim", [-1 3]));

            limits = figure_studio.sourceAxes.limitControls(plotData);

            testCase.verifyEqual(limits.xRange, [0 8]);
            testCase.verifyEqual(limits.yRange, [-3 5]);
            testCase.verifyEqual([limits.xMin limits.xMax], [2 6]);
            testCase.verifyEqual([limits.yMin limits.yMax], [-1 3]);
        end
    end
end

function closeAllTestFigures()
    delete(findall(groot, 'Type', 'figure'));
end

function types = childTypes(ax)
children = ax.Children;
types = strings(numel(children), 1);
for k = 1:numel(children)
    types(k) = string(children(k).Type);
end
end
