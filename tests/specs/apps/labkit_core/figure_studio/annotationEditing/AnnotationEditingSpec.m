classdef AnnotationEditingSpec < matlab.unittest.TestCase
    methods (Test, TestTags={'Contract:presentation', 'Env:headless'})
        function compoundAnnotationsRetainCategoryAndFineGrainedChildren(testCase)
            document = documentFixture();
            specification = struct("kind", "Significance bracket", ...
                "text", "p < 0.01", "x1", 1, "y1", 4, ...
                "x2", 2, "y2", 4);

            [document, ids] = figure_studio.figureDocument.addAnnotation( ...
                document, "panel-1", specification);
            nodes = document.nodes(ismember(string({document.nodes.id}), ids));

            testCase.verifyNumElements(nodes, 3);
            testCase.verifyEqual(nodes(1).kind, "group");
            testCase.verifyEqual(nodes(1).role, "compound-annotation");
            testCase.verifyEqual(nodes(2).groupId, nodes(1).id);
            testCase.verifyEqual(nodes(2).role, "significance-bracket");
            testCase.verifyEqual(nodes(3).role, "significance-label");
            testCase.verifyFalse(nodes(2).dataLocked);
        end

        function outOfRangeAnnotationExpandsAxesAndRefreshesTicks(testCase)
            document = documentFixture();
            originalTicks = [document.panels.axes.y.ticks.value];
            specification = struct("kind", "Text", "text", "Peak", ...
                "x1", 2, "y1", 12, "x2", 2, "y2", 12);

            document = figure_studio.figureDocument.addAnnotation( ...
                document, "panel-1", specification);

            testCase.verifyGreaterThan(document.panels.axes.y.limits(2), 12);
            testCase.verifyEqual(document.panels.axes.y.locator.mode, "auto");
            testCase.verifyNotEqual([document.panels.axes.y.ticks.value], ...
                originalTicks);
        end

        function deletingAGroupDeletesItsChildrenOnly(testCase)
            document = documentFixture();
            [document, ids] = figure_studio.figureDocument.addAnnotation( ...
                document, "panel-1", struct("kind", "Scale bar", ...
                    "text", "10 mm", "x1", 1, "y1", 1, ...
                    "x2", 3, "y2", 1));
            originalId = document.nodes(1).id;

            document = figure_studio.figureDocument.deleteNodes(document, ids(1));

            testCase.verifyEqual(string({document.nodes.id}), originalId);
        end

        function transformsCompoundAnnotationsWithoutChangingSourceData(testCase)
            document = documentFixture();
            sourceData = document.nodes(1).data;
            [document, ids] = figure_studio.figureDocument.addAnnotation( ...
                document, "panel-1", struct("kind", "Scale bar", ...
                    "text", "10 mm", "x1", 1, "y1", 1, ...
                    "x2", 3, "y2", 1));

            document = figure_studio.figureDocument.transformNodes( ...
                document, ids(1), "translate", ...
                struct("dx", 2, "dy", 3));

            lineNode = document.nodes(string({document.nodes.role}) == "scale-bar");
            testCase.verifyEqual(lineNode.data.x, [3 5]);
            testCase.verifyEqual(lineNode.data.y, [4 4]);
            testCase.verifyEqual(document.nodes(1).data, sourceData);
        end
    end
end

function document = documentFixture()
snapshot = struct("axes", struct("xLim", [0 5], "yLim", [0 5], ...
    "zLim", [0 1], "xTick", 0:5, "yTick", 0:5, "zTick", [], ...
    "xTickLabel", string(0:5), "yTickLabel", string(0:5), ...
    "zTickLabel", strings(0, 1)), ...
    "objects", struct("type", "line", "displayName", "Signal", ...
        "x", (0:5).', "y", (0:5).', "z", [], "c", [], "alpha", [], ...
        "style", struct(), "metadata", struct()));
document = figure_studio.figureDocument.create(snapshot);
end
