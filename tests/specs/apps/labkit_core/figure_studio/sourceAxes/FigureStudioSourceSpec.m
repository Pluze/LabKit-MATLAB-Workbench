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
    end
end

function types = childTypes(axesValue)
children = axesValue.Children;
types = strings(numel(children), 1);
for k = 1:numel(children)
    types(k) = string(children(k).Type);
end
end
