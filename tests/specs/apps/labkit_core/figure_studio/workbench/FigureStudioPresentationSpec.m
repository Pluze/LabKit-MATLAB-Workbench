classdef FigureStudioPresentationSpec < matlab.unittest.TestCase
    %FIGURESTUDIOPRESENTATIONSPEC Specify figure import, styling, and export controls.

    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function declaresFigureSourceStyleAndExportControls(testCase)
            plan = labkittest.inspectDefinition(figure_studio.definition());
            ids = string({plan.Nodes.Id});

            testCase.verifyTrue(all(ismember( ...
                ["preview" "outputFolder" "exportCurrent" ...
                "xScale" "yScale" "xDir" "yDir" "tickDir" ...
                "title" "xLabel" "yLabel" "canvasWidth" ...
                "canvasHeight" "outerMargin"], ids)));
            testCase.verifyFalse(any(ids == "appLog"));
        end
    end
end
