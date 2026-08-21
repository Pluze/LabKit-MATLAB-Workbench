classdef FigureStudioResultSpec < matlab.unittest.TestCase
    %FIGURESTUDIORESULTSPEC Specify semantic figure style output.

    methods (Test, TestTags = {'Contract:result', 'Env:headless'})
        function labKitPresetDefinesThePublicationStyleContract(testCase)
            style = figure_studio.styleLibrary.styleForPreset("LabKit figure");

            testCase.verifyEqual([style.canvasWidth style.canvasHeight style.exportScale], ...
                [900 725 2]);
            testCase.verifyEqual([style.titleFontSize style.labelFontSize ...
                style.tickFontSize style.annotationFontSize style.legendFontSize], ...
                [45 45 45 45 45]);
            testCase.verifyEqual(style.legendTokenWidth, 100);
            testCase.verifyFalse(style.gridVisible);
            testCase.verifyTrue(style.boundaryLines);
        end

        function styleApplicationScalesAxesAndDataLinesWithTheCanvas(testCase)
            cleanup = onCleanup(@() close(findall(groot, "Type", "figure")));
            figureValue = figure(Visible="off");
            axesValue = axes(Parent=figureValue);
            lineValue = plot(axesValue, 1:3, [2 4 3]);
            title(axesValue, "Scale probe");
            style = figure_studio.styleLibrary.styleForPreset("LabKit figure");
            style.canvasWidth = 1800;
            style.canvasHeight = 1450;

            figure_studio.resultFiles.applyFigureStyle(axesValue, style);

            testCase.verifyEqual(axesValue.FontSize, 90);
            testCase.verifyEqual(axesValue.Title.FontSize, 90);
            testCase.verifyEqual(lineValue.LineWidth, 2 .* style.dataLineWidth, AbsTol=1e-12);
            clear cleanup
        end

        function standardizesSemanticStrokeCategories(testCase)
            cleanup = onCleanup(@() close(findall(groot, "Type", "figure")));
            figureValue = figure(Visible="off");
            axesValue = axes(Parent=figureValue);
            hold(axesValue, "on");
            data = plot(axesValue, [1 2], [2 3], LineWidth=9);
            comparison = plot(axesValue, [1 1 2 2], [3 3.2 3.2 3], ...
                HandleVisibility="off", LineWidth=9);
            comparisonLabel = text(axesValue, 1.5, 3.21, "**", ...
                HorizontalAlignment="center", VerticalAlignment="bottom");
            boundary = bar(axesValue, 3, 2.5, LineWidth=9);
            uncertainty = errorbar(axesValue, 3, 2.5, 0.4, LineWidth=9);
            hold(axesValue, "off");
            style = figure_studio.styleLibrary.styleForPreset("LabKit figure");

            figure_studio.resultFiles.applyFigureStyle(axesValue, style);

            testCase.verifyEqual(data.LineWidth, style.dataLineWidth);
            testCase.verifyEqual(comparison.LineWidth, ...
                style.referenceLineWidth);
            testCase.verifyEqual(boundary.LineWidth, ...
                style.boundaryLineWidth);
            testCase.verifyEqual(string(boundary.FaceColor), "none");
            testCase.verifyEqual(string(boundary.EdgeColor), "flat");
            testCase.verifyEqual(boundary.CData, style.colorOrder(1, :));
            testCase.verifyEqual(uncertainty.LineWidth, ...
                style.uncertaintyLineWidth);
            testCase.verifyEqual(axesValue.LineWidth, style.axesLineWidth);
            testCase.verifyGreaterThan(comparisonLabel.Position(2), 3.2);
            testCase.verifyGreaterThan(axesValue.YLim(2), ...
                comparisonLabel.Position(2));
            clear cleanup
        end

        function wrapsLongCategoryLabelsWithoutChangingTheFrame(testCase)
            cleanup = onCleanup(@() close(findall(groot, "Type", "figure")));
            figureValue = figure(Visible="off");
            axesValue = axes(Parent=figureValue);
            bar(axesValue, 1:3, [2 3 4]);
            axesValue.XTick = 1:3;
            axesValue.XTickLabel = {"Reference group", ...
                "Treatment group A", "Treatment group B"};
            style = figure_studio.styleLibrary.styleForPreset("LabKit figure");
            style.wrapXTickLabels = true;

            figure_studio.resultFiles.applyFigureStyle(axesValue, style);

            labels = findall(axesValue, "Type", "text", ...
                "Tag", "figureStudioWrappedXTickLabel");
            testCase.verifyNumElements(labels, 3);
            for label = reshape(labels, 1, [])
                value = label.String;
                isMultipleRows = ischar(value) && size(value, 1) >= 2;
                textRows = string(value);
                hasNewline = any(contains(textRows, newline));
                testCase.verifyTrue(isMultipleRows || ...
                    numel(textRows) >= 2 || hasNewline);
            end
            testCase.verifyEqual(axesValue.XTickLabelRotation, 0);
            pixelPosition = getpixelposition(axesValue, true);
            testCase.verifyEqual(pixelPosition(3:4), ...
                [style.canvasWidth style.canvasHeight], AbsTol=1);
            clear cleanup
        end

        function nativeExportUsesThePreviewPlotBoxAspect(testCase)
            cleanup = onCleanup(@() close(findall(groot, "Type", "figure")));
            sourceFigure = figure(Visible="off");
            source = axes(Parent=sourceFigure);
            semilogx(source, logspace(-1, 5), linspace(700, 0, 50));
            pbaspect(source, [1 1 1]);
            plotData = figure_studio.resultFiles.extractAxesData(source);
            style = figure_studio.styleLibrary.styleForPreset("LabKit figure");
            previewFigure = figure(Visible="off");
            preview = axes(Parent=previewFigure);
            model = struct("plotData", plotData, "sourceAxes", source, ...
                "style", style, "preview", true);

            figure_studio.sourceAxes.drawPreview( ...
                struct("main", preview), model);
            [exportFigure, exported] = ...
                figure_studio.resultFiles.createStyledFigure( ...
                plotData, style, source);
            exportCleanup = onCleanup(@() delete(exportFigure));

            expected = style.canvasWidth / style.canvasHeight;
            previewRatio = preview.PlotBoxAspectRatio(1) / ...
                preview.PlotBoxAspectRatio(2);
            exportRatio = exported.PlotBoxAspectRatio(1) / ...
                exported.PlotBoxAspectRatio(2);
            testCase.verifyEqual(previewRatio, expected, AbsTol=1e-12);
            testCase.verifyEqual(exportRatio, previewRatio, AbsTol=1e-12);
            testCase.verifyEqual(exported.XTick, preview.XTick);
            testCase.verifyEqual(string(exported.XTickLabel), ...
                string(preview.XTickLabel));
            clear exportCleanup cleanup
        end

        function figImportPreservesCompositeScientificGraphicsAndLegend(testCase)
            cleanup = onCleanup(@() close(findall(groot, "Type", "figure")));
            sourceFigure = figure(Visible="off");
            source = axes(Parent=sourceFigure);
            hold(source, "on");
            bar(source, 1:3, [2 4 3], DisplayName="Mean");
            errorbar(source, 1:3, [2 4 3], [.2 .3 .1], DisplayName="Uncertainty");
            rectangle(source, Position=[1.2 1.5 1.5 2]);
            xline(source, 2, "-", "Scientific threshold");
            text(source, 2, 4.8, "annotation");
            legend(source, "show", Location="northwest", Orientation="horizontal", Box="on");
            path = string(tempname) + ".fig";
            savefig(sourceFigure, path);
            fileCleanup = onCleanup(@() deleteIfFile(path));

            [plotData, style, resource] = figure_studio.sourceAxes.readFigFile(path);
            resourceCleanup = onCleanup(@() figure_studio.sourceAxes.closeResource(resource));
            [rebuiltFigure, rebuilt] = figure_studio.resultFiles.createStyledFigure( ...
                plotData, style, resource.axes);
            rebuiltCleanup = onCleanup(@() delete(rebuiltFigure));
            types = string(get(findall(rebuilt, "-property", "Type"), "Type"));

            testCase.verifyTrue(all(ismember( ...
                ["bar", "errorbar", "rectangle", "constantline", "text"], types)));
            testCase.verifyNotEmpty(rebuilt.Legend);
            testCase.verifyEqual(string(rebuilt.Legend.Location), "northwest");
            testCase.verifyEqual(string(rebuilt.Legend.Orientation), "horizontal");
            rebuilt.Units = "pixels";
            testCase.verifyEqual(rebuilt.Position(3:4), ...
                round([style.canvasWidth style.canvasHeight]), AbsTol=1);
            clear rebuiltCleanup resourceCleanup fileCleanup cleanup
        end

        function exportedAxisLabelsRetainOuterWhitespace(testCase)
            cleanup = onCleanup(@() close(findall(groot, "Type", "figure")));
            sourceFigure = figure(Visible="off");
            source = axes(Parent=sourceFigure);
            plot(source, 0:5, [0 2 4 3 2 1]);
            title(source, "Impedance plot");
            xlabel(source, "Zreal (ohm)");
            ylabel(source, "-Zimag (ohm)");
            output = labkittest.visualEvidencePath( ...
                "figure-studio-axis-label-margins", ".png");
            project = figure_studio.initialData();
            project.parameters.style.exportScale = 0.25;
            session = struct("cache", struct( ...
                "plotData", ...
                    figure_studio.resultFiles.extractAxesData(source), ...
                "sourceAxes", source, "currentSource", ""));
            state = struct("project", project, "session", session);
            backend = struct( ...
                "chooseOutputFile", @(~, ~) ...
                    labkit.app.dialog.Choice(output), ...
                "writeResult", @writeResultProbe, ...
                "log", @ignoreLog);
            context = labkittest.createCallbackContext(backend);

            figure_studio.resultFiles.exportGraphic(state, context, "png");

            image = imread(output);
            bottomEdge = reshape(image(end, :, :), [], 1);
            leftEdge = reshape(image(:, 1, :), [], 1);
            testCase.verifyTrue(all(bottomEdge >= 245), ...
                edgeDiagnostic(bottomEdge, "bottom"));
            testCase.verifyTrue(all(leftEdge >= 245), ...
                edgeDiagnostic(leftEdge, "left"));
            clear cleanup
        end

        function emptyLogRulerTextDoesNotCreateAnOversizedCanvas(testCase)
            cleanup = onCleanup(@() close(findall(groot, "Type", "figure")));
            figureValue = figure(Visible="off", MenuBar="none", ToolBar="none");
            axesValue = axes(Parent=figureValue);
            loglog(axesValue, [1 1e5], [1e5 1e2]);
            xlabel(axesValue, "Frequency (Hz)");
            ylabel(axesValue, "Impedance (ohm)");

            figure_studio.resultFiles.applyFigureStyle(axesValue, ...
                figure_studio.styleLibrary.styleForPreset("LabKit figure"));
            axesValue.Units = "pixels";

            testCase.verifyEqual(axesValue.Position(3:4), [900 725], AbsTol=1);
            testCase.verifyLessThan(figureValue.InnerPosition(3), 2000);
            testCase.verifyLessThan(figureValue.InnerPosition(4), 2000);
            clear cleanup
        end
    end
end

function deleteIfFile(path)
if isfile(path)
    delete(path);
end
end

function written = writeResultProbe(folder, ~)
written = labkit.app.dialog.Choice(fullfile(folder, "manifest.json"));
end

function ignoreLog(varargin)
end

function message = edgeDiagnostic(edge, name)
dark = find(edge < 245);
if isempty(dark)
    span = "none";
else
    span = string(dark(1)) + ":" + string(dark(end));
end
message = sprintf( ...
    "Rendered ink reaches the %s image boundary (%d channel values, span %s).", ...
    name, numel(dark), span);
end
