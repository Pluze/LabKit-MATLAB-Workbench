classdef FigureStudioSourceSpec < matlab.unittest.TestCase
    %FIGURESTUDIOSOURCESPEC Specify imported axes limits and graphics stacking.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function derivesFiftyPercentLimitControlEnvelopesFromPlotData(testCase)
            plotData = struct("objects", struct("type", "line", ...
                "x", [2; 6], "y", [-1; 3]), ...
                "axes", struct("xLim", [2 6], "yLim", [-1 3]));

            limits = figure_studio.sourceAxes.limitControls(plotData);

            testCase.verifyEqual(limits.xRange, [0 8]);
            testCase.verifyEqual(limits.yRange, [-3 5]);
            testCase.verifyEqual([limits.xMin limits.xMax], [2 6]);
            testCase.verifyEqual([limits.yMin limits.yMax], [-1 3]);
        end

        function copiesAnImageOverlayStackWithoutChangingTheOrder(testCase)
            cleanup = onCleanup(@() close(findall(groot, "Type", "figure")));
            sourceFigure = figure(Visible="off");
            source = axes(Parent=sourceFigure);
            image(source, CData=uint8(80 .* ones(12, 16, 3)), ...
                XData=[0 1], YData=[0 1]);
            hold(source, "on");
            line(source, [.1 .9], [.2 .8], Color=[1 0 0]);
            text(source, .5, .6, "overlay");
            previewFigure = figure(Visible="off");
            preview = axes(Parent=previewFigure);

            figure_studio.sourceAxes.copyToPreview(source, preview);

            testCase.verifyEqual(childTypes(preview), childTypes(source));
            testCase.verifyEqual(childTypes(preview), ["text"; "line"; "image"]);
            clear cleanup
        end

        function preservesManualNativeGeometryDuringPreviewCopy(testCase)
            cleanup = onCleanup(@() close(findall(groot, "Type", "figure")));
            sourceFigure = figure(Visible="off");
            source = axes(Parent=sourceFigure);
            plot(source, linspace(0, 30, 200), sin(linspace(0, 30, 200)));
            pbaspect(source, [2 1 1]);
            daspect(source, [10 1 1]);
            previewFigure = figure(Visible="off");
            preview = axes(Parent=previewFigure);

            figure_studio.sourceAxes.copyToPreview(source, preview);

            testCase.verifyEqual(string(preview.PlotBoxAspectRatioMode), "manual");
            testCase.verifyEqual(string(preview.DataAspectRatioMode), "manual");
            testCase.verifyNumElements(preview.Children, numel(source.Children));
            clear cleanup
        end

        function distinguishesDisplayedFigCanvasFromExplicitAxesHandoff(testCase)
            cleanup = onCleanup(@() close(findall(groot, "Type", "figure")));
            sourceFigure = figure(Visible="off", Units="pixels", Position=[100 100 720 540]);
            source = axes(Parent=sourceFigure, Units="normalized", ...
                Position=[.13 .34 .775 .58]);
            plot(source, 1:4, [1 3 2 4]);
            pbaspect(source, [2 1 1]);

            figStyle = figure_studio.sourceAxes.sourceStyle(source, PreserveAspect=false);
            axesStyle = figure_studio.sourceAxes.sourceStyle(source);

            testCase.verifyGreaterThan(figStyle.canvasWidth / figStyle.canvasHeight, 1.2);
            testCase.verifyLessThan(figStyle.canvasWidth / figStyle.canvasHeight, 3);
            testCase.verifyEmpty(figStyle.axesPosition);
            testCase.verifyLessThan(abs(axesStyle.canvasWidth / axesStyle.canvasHeight - 2), .02);
            clear cleanup
        end

        function standardLayoutRestoresReferenceGeometry(testCase)
            standard = figure_studio.styleLibrary.styleForPreset("LabKit figure");
            plotData = struct("axes", struct("xTickLabel", ...
                ["Reference group"; "Treatment group A"; ...
                "Treatment group B"]));

            [actual, aspect, sizeChoice] = ...
                figure_studio.sourceAxes.applyStandardLayout( ...
                standard, plotData);

            testCase.verifyEqual([actual.canvasWidth actual.canvasHeight], ...
                [standard.canvasWidth standard.canvasHeight]);
            testCase.verifyEqual([actual.referenceCanvasWidth ...
                actual.referenceCanvasHeight], ...
                [standard.referenceCanvasWidth ...
                standard.referenceCanvasHeight]);
            testCase.verifyEqual([actual.titleFontSize actual.labelFontSize ...
                actual.tickFontSize actual.annotationFontSize], ...
                [standard.titleFontSize standard.labelFontSize ...
                standard.tickFontSize standard.annotationFontSize]);
            testCase.verifyEqual(actual.xTickLabelAngle, "Horizontal");
            testCase.verifyTrue(actual.wrapXTickLabels);
            testCase.verifyEqual(aspect, "Reference");
            testCase.verifyEqual(sizeChoice, "900 px");
        end

        function axesHandoffBuildsAnEmbeddedProjectWithoutSourceFileState(testCase)
            cleanup = onCleanup(@() close(findall(groot, "Type", "figure")));
            sourceFigure = figure(Visible="off");
            source = axes(Parent=sourceFigure);
            plot(source, 1:4, [2 1 4 3]);
            title(source, "Source handoff");

            [project, dispatch] = figure_studio.launchRequest({"axes", source});

            testCase.verifyEmpty(dispatch);
            testCase.verifyEmpty(project.inputs.sources);
            testCase.verifyNotEmpty(project.annotations.embeddedPlot.objects);
            testCase.verifyEqual(project.parameters.preset, "LabKit figure");
            testCase.verifyTrue(isgraphics(project.annotations.transientSourceAxes, "axes"));
            testCase.verifyError(@() figure_studio.launchRequest({"axes", []}), ...
                "labkit_FigureStudio_app:InvalidAxes");
            clear cleanup
        end
    end
end

function types = childTypes(axesValue)
children = axesValue.Children;
types = strings(numel(children), 1);
for k = 1:numel(children)
    types(k) = string(children(k).Type);
end
end
