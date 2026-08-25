classdef SemanticDocumentSpec < matlab.unittest.TestCase
    %SEMANTICDOCUMENTSPEC Specify the editable Figure Studio document core.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function importsMultiplePanelsWithDataLockedSemanticNodes(testCase)
            first = snapshot("Waveform", [lineObject("Raw", "-"), ...
                errorObject("SD")]);
            second = snapshot("Image", imageObject());

            document = figure_studio.figureDocument.create({first, second});

            testCase.verifyEqual(document.schema, "figure-studio-document");
            testCase.verifyEqual(string({document.panels.name}), ...
                ["Waveform" "Image"]);
            testCase.verifyEqual(string({document.nodes.kind}), ...
                ["line" "errorbar" "image"]);
            testCase.verifyEqual(string({document.nodes.role}), ...
                ["raw-data" "uncertainty" "image"]);
            testCase.verifyTrue(all([document.nodes.dataLocked]));
            testCase.verifyEqual(document.nodes(1).data.y, [2 4 3]);
        end

        function resolvesCategoryStylesBeforeObjectOverrides(testCase)
            document = figure_studio.figureDocument.create( ...
                snapshot("Series", [lineObject("A", "-"), ...
                lineObject("B", "-")]));
            document = figure_studio.figureDocument.setStyle( ...
                document, "kind", "line", "LineWidth", 1.5);
            document = figure_studio.figureDocument.setStyle( ...
                document, "role", "raw-data", "Color", [0 0 0]);
            document = figure_studio.figureDocument.setStyle( ...
                document, "object", "object-2", "LineWidth", 2.5);

            [first, firstSources] = ...
                figure_studio.figureDocument.effectiveStyle(document, "object-1");
            second = figure_studio.figureDocument.effectiveStyle( ...
                document, "object-2");
            state = figure_studio.figureDocument.propertyState( ...
                document, ["object-1", "object-2"], "LineWidth");

            testCase.verifyEqual(first.LineWidth, 1.5);
            testCase.verifyEqual(first.Color, [0 0 0]);
            testCase.verifyEqual(firstSources.LineWidth, "kind:line");
            testCase.verifyEqual(second.LineWidth, 2.5);
            testCase.verifyEqual(state.kind, "mixed");
        end

        function expandedLimitsRegenerateAutomaticTickText(testCase)
            data = snapshot("Axis", lineObject("Trace", "-"));
            data.axes.xTick = 0:0.5:1;
            data.axes.xTickLabel = ["0" "0.5" "1"];
            document = figure_studio.figureDocument.create(data);
            document.panels(1).axes.x.locator.mode = "nice-count";
            document.panels(1).axes.x.locator.count = 5;

            document = figure_studio.figureDocument.setAxisLimits( ...
                document, "panel-1", "x", [-1 3]);

            ticks = document.panels(1).axes.x.ticks;
            testCase.verifyEqual([ticks.value], -1:3);
            testCase.verifyEqual(string({ticks.label}), ...
                ["-1" "0" "1" "2" "3"]);
        end

        function explicitTicksRetainPerTickLabelsOutsideTheViewport(testCase)
            data = snapshot("Axis", lineObject("Trace", "-"));
            data.axes.xTick = [-2 0 2];
            data.axes.xTickLabel = ["Before" "Zero" "After"];

            document = figure_studio.figureDocument.create(data);
            document.panels(1).axes.x.locator.mode = "explicit";
            document.panels(1).axes.x.formatter.mode = "explicit";
            document = figure_studio.figureDocument.setAxisLimits( ...
                document, "panel-1", "x", [-1 1]);

            ticks = document.panels(1).axes.x.ticks;
            testCase.verifyEqual([ticks.value], [-2 0 2]);
            testCase.verifyEqual(string({ticks.label}), ...
                ["Before" "Zero" "After"]);
        end

        function historyRestoresWholeDocumentTransactions(testCase)
            original = figure_studio.figureDocument.create( ...
                snapshot("History", lineObject("Trace", "-")));
            historyValue = figure_studio.figureDocument.history( ...
                "create", [], original);
            [historyValue, ~] = figure_studio.figureDocument.history( ...
                "commit", historyValue, original, "Set line width");
            changed = figure_studio.figureDocument.setStyle( ...
                original, "object", "object-1", "LineWidth", 3);

            [historyValue, undone] = figure_studio.figureDocument.history( ...
                "undo", historyValue, changed);
            [~, redone] = figure_studio.figureDocument.history( ...
                "redo", historyValue, undone);

            testCase.verifyEqual(undone.revision, original.revision);
            style = figure_studio.figureDocument.effectiveStyle( ...
                redone, "object-1");
            testCase.verifyEqual(style.LineWidth, 3);
        end

        function groupsDuplicatesAndReordersWithoutUnlockingData(testCase)
            document = figure_studio.figureDocument.create( ...
                snapshot("Layers", [lineObject("A", "-"), ...
                lineObject("B", "-"), lineObject("C", "-")]));

            [document, groupId] = figure_studio.figureDocument.groupNodes( ...
                document, ["object-1", "object-2"], "Signals");
            [document, copies] = figure_studio.figureDocument.duplicateNodes( ...
                document, "object-3");
            document = figure_studio.figureDocument.reorderNodes( ...
                document, copies, "back");

            members = document.nodes(ismember(string({document.nodes.id}), ...
                ["object-1", "object-2"]));
            testCase.verifyEqual(string({members.groupId}), [groupId groupId]);
            copy = document.nodes(string({document.nodes.id}) == copies);
            testCase.verifyTrue(copy.dataLocked);
            testCase.verifyEqual(copy.metadata.duplicatedFrom, "object-3");
            objectOrder = string({document.nodes( ...
                string({document.nodes.kind}) ~= "group").id});
            testCase.verifyEqual(objectOrder(1), copies);

            document = figure_studio.figureDocument.ungroupNodes( ...
                document, ["object-1", "object-2"]);
            testCase.verifyFalse(any(string({document.nodes.id}) == groupId));
        end
    end
end

function value = snapshot(titleText, objects)
value = struct();
value.axes = struct( ...
    "title", titleText, "subtitle", "", ...
    "xLabel", "Time (s)", "yLabel", "Response", "zLabel", "", ...
    "xScale", "linear", "yScale", "linear", "zScale", "linear", ...
    "xDir", "normal", "yDir", "normal", "zDir", "normal", ...
    "xLim", [0 1], "yLim", [0 5], "zLim", [0 1], ...
    "xTick", [0 .5 1], "yTick", 0:5, "zTick", [], ...
    "xTickLabel", ["0" ".5" "1"], ...
    "yTickLabel", string(0:5), "zTickLabel", strings(0, 1), ...
    "xAxisLocation", "bottom", "yAxisLocation", "left", ...
    "cLim", [0 1], "colormap", []);
value.objects = reshape(objects, [], 1);
end

function object = lineObject(name, lineStyle)
object = objectTemplate("line", name);
object.x = [0 0.5 1];
object.y = [2 4 3];
object.style = struct("Color", [0.1 0.2 0.3], ...
    "LineStyle", lineStyle, "LineWidth", 1);
end

function object = errorObject(name)
object = objectTemplate("errorbar", name);
object.x = [0 0.5 1];
object.y = [2 4 3];
object.style = struct("Color", [0 0 0], ...
    "LineStyle", "none", "LineWidth", 1);
object.metadata.yNegativeDelta = [.2 .3 .2];
object.metadata.yPositiveDelta = [.2 .3 .2];
end

function object = imageObject()
object = objectTemplate("image", "Thermal image");
object.c = reshape(1:12, 3, 4);
object.x = [1 4];
object.y = [1 3];
object.style = struct("CDataMapping", "scaled");
end

function object = objectTemplate(type, name)
object = struct( ...
    "type", type, "displayName", name, ...
    "x", [], "y", [], "z", [], "c", [], "alpha", [], ...
    "style", struct(), ...
    "metadata", struct("handleVisibility", "on"));
end
