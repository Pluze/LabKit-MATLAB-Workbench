classdef AxesHandoffLayoutSpec < matlab.unittest.TestCase
    % AXESHANDOFFLAYOUTSPEC Regression: axes handoff must restore the publication frame without rewriting labels.

    methods (Test, TestTags = {'Contract:product', 'Env:headless'})
        function provesAxesHandoffLayout(testCase)
            cleanup = onCleanup(@() close(findall(groot, "Type", "figure")));
            sourceFigure = figure(Visible="off", Units="pixels", ...
                Position=[100 100 1394 900]);
            source = axes(Parent=sourceFigure, FontSize=14);
            bar(source, 1:3, [28 27 24], FaceColor=[0.7 0.8 0.9], ...
                LineWidth=0.8);
            text(source, 2, 35, "***", FontSize=16);
            source.XTick = 1:3;
            source.XTickLabel = { ...
                'Reference group', 'Treatment group A', ...
                'Treatment group B'};
            pbaspect(source, [1.7 1 1]);

            [project, dispatch] = figure_studio.launchRequest({"axes", source});
            standard = figure_studio.styleLibrary.styleForPreset("Published figure");
            active = project.parameters.style;

            testCase.verifyEmpty(dispatch);
            testCase.verifyEqual(project.parameters.preset, "Published figure");
            testCase.verifyEqual(project.parameters.aspectPreset, "Published");
            testCase.verifyEqual(active.canvasWidth, standard.canvasWidth);
            testCase.verifyEqual(active.canvasHeight, standard.canvasHeight);
            testCase.verifyEqual([active.referenceCanvasWidth ...
                active.referenceCanvasHeight], ...
                [active.canvasWidth active.canvasHeight]);
            testCase.verifyEqual([active.titleFontSize active.labelFontSize ...
                active.tickFontSize active.annotationFontSize], ...
                [standard.titleFontSize standard.labelFontSize ...
                standard.tickFontSize standard.annotationFontSize]);
            testCase.verifyEqual(active.colorOrder, standard.colorOrder);
            testCase.verifyEqual(active.xTickLabelAngle, "Source");
            testCase.verifyFalse(active.wrapXTickLabels);
            clear cleanup
        end
    end
end
