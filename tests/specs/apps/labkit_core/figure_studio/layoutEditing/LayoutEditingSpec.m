classdef LayoutEditingSpec < matlab.unittest.TestCase
    methods (Test, TestTags={'Contract:presentation', 'Env:headless'})
        function createsNonoverlappingGridAndAlignsSelectedPanels(testCase)
            document = figure_studio.figureDocument.create( ...
                {snapshot("A"), snapshot("B"), snapshot("C")});

            testCase.verifyNumElements(document.panels, 3);
            for left = 1:3
                for right = left+1:3
                    testCase.verifyEqual(overlap( ...
                        document.panels(left).geometry, ...
                        document.panels(right).geometry), 0, AbsTol=1e-12);
                end
            end

            ids = string({document.panels(1:2).id});
            document = figure_studio.figureDocument.panelOperation( ...
                document, ids, "Align left");
            testCase.verifyEqual(document.panels(1).geometry(1), ...
                document.panels(2).geometry(1));
        end

        function duplicatesPanelWithIndependentNodeIdentity(testCase)
            document = figure_studio.figureDocument.create(snapshot("A"));

            [document, ids] = figure_studio.figureDocument.duplicatePanels( ...
                document, "panel-1");

            testCase.verifyNumElements(document.panels, 2);
            testCase.verifyEqual(ids, "panel-2");
            testCase.verifyNumElements(unique(string({document.nodes.id})), 2);
            testCase.verifyEqual(document.nodes(2).panelId, "panel-2");
        end

        function rendersAllPanelsAtExactDocumentGeometry(testCase)
            cleanup = onCleanup(@() close(findall(groot, "Type", "figure")));
            document = figure_studio.figureDocument.create( ...
                {snapshot("A"), snapshot("B")});
            document.canvas.width = 800;
            document.canvas.height = 600;
            document.canvas.padding = [40 20 30 10];
            style = figure_studio.styleLibrary.styleForPreset("LabKit figure");

            [fig, axesValues] = figure_studio.resultFiles.createStyledFigure( ...
                figure_studio.figureDocument.toPlotData(document, "panel-1"), ...
                style, [], document);

            testCase.verifyNumElements(axesValues, 2);
            testCase.verifyEqual(fig.Position(3:4), [800 600], AbsTol=1);
            testCase.verifyGreaterThan(axesValues(1).Position(1), 39);
            testCase.verifyGreaterThan(axesValues(1).Position(3), 300);
            clear cleanup
        end
    end
end

function data = snapshot(titleValue)
axesData = struct("title", titleValue, "subtitle", "", ...
    "xLabel", "Time (s)", "yLabel", "Signal", "zLabel", "", ...
    "xScale", "linear", "yScale", "linear", "zScale", "linear", ...
    "xDir", "normal", "yDir", "normal", "zDir", "normal", ...
    "xLim", [0 2], "yLim", [0 3], "zLim", [0 1], ...
    "xTick", 0:2, "yTick", 0:3, "zTick", [], ...
    "xTickLabel", string(0:2), "yTickLabel", string(0:3), ...
    "zTickLabel", strings(0, 1), "cLim", [0 1], "colormap", []);
object = struct("type", "line", "displayName", titleValue, ...
    "x", (0:2).', "y", (1:3).', "z", [], "c", [], "alpha", [], ...
    "style", struct("Color", [0 0 0]), ...
    "metadata", struct("handleVisibility", "on"));
data = struct("axes", axesData, "objects", object, ...
    "warnings", strings(0, 1));
end

function value = overlap(a, b)
value = max(0, min(a(1)+a(3), b(1)+b(3)) - max(a(1), b(1))) * ...
    max(0, min(a(2)+a(4), b(2)+b(4)) - max(a(2), b(2)));
end
