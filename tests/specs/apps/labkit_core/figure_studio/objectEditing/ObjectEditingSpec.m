classdef ObjectEditingSpec < matlab.unittest.TestCase
    %OBJECTEDITINGSPEC Specify layer and cascade editing behavior.

    methods (Test, TestTags = {'Contract:source', 'Env:headless'})
        function appliesRoleStyleThenOverridesOneSelectedObject(testCase)
            [state, context] = stateFixture();
            original = state.session.editor.document.nodes(1).data.y;
            state.session.editor.document.selection = ["object-1"; "object-2"];
            state.session.editor.activeScope = "Role";
            state.session.editor.activeProperty = "LineWidth";
            state.session.editor.propertyDraft = "2";
            state = figure_studio.objectEditing.applyStyle(state, context);
            state.session.editor.document.selection = "object-2";
            state.session.editor.activeScope = "Selection";
            state.session.editor.propertyDraft = "3.5";
            state = figure_studio.objectEditing.applyStyle(state, context);

            first = figure_studio.figureDocument.effectiveStyle( ...
                state.session.editor.document, "object-1");
            second = figure_studio.figureDocument.effectiveStyle( ...
                state.session.editor.document, "object-2");
            testCase.verifyEqual(first.LineWidth, 2);
            testCase.verifyEqual(second.LineWidth, 3.5);
            testCase.verifyEqual( ...
                state.session.editor.document.nodes(1).data.y, original);
            testCase.verifyTrue(state.session.editor.document.nodes(1).dataLocked);
        end

        function groupsDuplicatesAndMovesSelectedObjectsToPortableRendering(testCase)
            [state, context] = stateFixture();
            state.session.editor.document.selection = ["object-1"; "object-2"];
            state = figure_studio.objectEditing.group(state, context);
            groupId = state.session.editor.document.selection;
            testCase.verifyTrue(startsWith(groupId, "group-"));

            state = figure_studio.objectEditing.duplicate(state, context);
            testCase.verifyFalse(state.session.editor.nativePassThrough);
            copies = state.session.editor.document.selection;
            testCase.verifyNumElements(copies, 2);
            state = figure_studio.objectEditing.toBack(state, context);
            objectIds = string({state.session.editor.document.nodes( ...
                string({state.session.editor.document.nodes.kind}) ~= "group").id});
            testCase.verifyEqual(objectIds(1:2).', copies);
        end

        function editsLayerVisibilityRoleAndNameFromTypedTableEvents(testCase)
            [state, context] = stateFixture();
            state = figure_studio.objectEditing.editObject(state, ...
                labkit.app.event.TableCellEdit(RowIndex=1, ColumnIndex=1, ...
                    PreviousValue=true, NewValue=false), context);
            state = figure_studio.objectEditing.editObject(state, ...
                labkit.app.event.TableCellEdit(RowIndex=1, ColumnIndex=5, ...
                    PreviousValue="raw-data", NewValue="fit"), context);
            state = figure_studio.objectEditing.editObject(state, ...
                labkit.app.event.TableCellEdit(RowIndex=1, ColumnIndex=6, ...
                    PreviousValue="A", NewValue="Calibrated fit"), context);

            node = state.session.editor.document.nodes(1);
            testCase.verifyFalse(node.visible);
            testCase.verifyEqual(node.role, "fit");
            testCase.verifyEqual(node.name, "Calibrated fit");
        end
    end
end

function [state, context] = stateFixture()
objects = [lineObject("A"), lineObject("B"), lineObject("C")];
axesData = struct("title", "Source", "subtitle", "", ...
    "xLabel", "X", "yLabel", "Y", "zLabel", "", ...
    "xScale", "linear", "yScale", "linear", "zScale", "linear", ...
    "xDir", "normal", "yDir", "normal", "zDir", "normal", ...
    "xLim", [0 1], "yLim", [0 5], "zLim", [0 1], ...
    "xTick", [0 .5 1], "yTick", 0:5, "zTick", [], ...
    "xTickLabel", ["0" "0.5" "1"], ...
    "yTickLabel", string(0:5), "zTickLabel", strings(0, 1), ...
    "xAxisLocation", "bottom", "yAxisLocation", "left", ...
    "cLim", [0 1], "colormap", []);
plotData = struct("axes", axesData, "objects", objects, ...
    "warnings", strings(0, 1));
project = figure_studio.initialData();
state = struct("project", project, "session", struct( ...
    "editor", figure_studio.figureDocument.editorState(plotData), ...
    "cache", struct("plotData", plotData, ...
        "limitState", figure_studio.sourceAxes.limitControls(plotData), ...
        "viewRevision", 1), ...
    "workflow", struct("status", "")));
context = labkittest.createCallbackContext(struct("log", @ignoreLog));
end

function object = lineObject(name)
object = struct("type", "line", "displayName", name, ...
    "x", [0 .5 1], "y", [2 4 3], "z", [], "c", [], "alpha", [], ...
    "style", struct("Color", [0 0 0], "LineWidth", 1, ...
        "LineStyle", "-"), ...
    "metadata", struct("handleVisibility", "on"));
end

function ignoreLog(varargin)
end
