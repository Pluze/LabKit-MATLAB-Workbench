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
    end
end

function deleteIfFile(path)
if isfile(path)
    delete(path);
end
end
