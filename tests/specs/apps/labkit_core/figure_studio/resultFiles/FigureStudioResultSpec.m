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
    end
end
