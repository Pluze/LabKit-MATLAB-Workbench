classdef PreflightSpec < matlab.unittest.TestCase
    methods (Test, TestTags={'Contract:result', 'Env:headless'})
        function checksEachSeriesAgainstItsOwnYAxis(testCase)
            document = figure_studio.figureDocument.create(snapshot());
            document.panels.axes.y.scale = "linear";
            document.panels.axes.y.limits = [-1 3];
            document.panels.axes.yRight = document.panels.axes.y;
            document.panels.axes.yRight.scale = "log";
            document.panels.axes.yRight.limits = [10 30];
            right = document.nodes(1);
            right.id = "right-series";
            right.data.y = [10; 20; 30];
            right.metadata.yAxisSide = "right";
            document.nodes(2) = right;
            style = figure_studio.styleLibrary.styleForPreset("LabKit figure");
            report = figure_studio.preflight.check(document, style);
            testCase.verifyEqual(report.errors, 0);
            testCase.verifyFalse(any(string({report.issues.code}) == "object-outside-limits"));
            document.nodes(2).data.y(1) = -10;
            report = figure_studio.preflight.check(document, style);
            testCase.verifyTrue(any(string({report.issues.code}) == "nonpositive-log-data"));
            document.panels.axes.yRight.scale = "linear";
            document.panels.axes.y.scale = "log";
            document.panels.axes.y.limits = [1 3];
            document.nodes(1).data.y = [1; 2; 3];
            report = figure_studio.preflight.check(document, style);
            testCase.verifyEqual(report.errors, 0);
        end

        function reportsActionableScientificPresentationRisks(testCase)
            document = figure_studio.figureDocument.create(snapshot());
            document.panels.axes.y.scale = "log";
            document.panels.text.xLabel = "";
            document.nodes.metadata.yAxisSideConfidence = "fallback";
            style = figure_studio.styleLibrary.styleForPreset("LabKit figure");
            style.annotationFontSize = 5;

            report = figure_studio.preflight.check(document, style);
            codes = string({report.issues.code});

            testCase.verifyEqual(report.status, "blocked");
            testCase.verifyTrue(all(ismember(["nonpositive-log-data", ...
                "missing-x-label", "ambiguous-y-axis", "small-text"], codes)));
            testCase.verifyTrue(all(strlength(string({report.issues.suggestedFix})) > 0));
        end
    end
end

function data = snapshot()
axesData = struct("title", "", "subtitle", "", "xLabel", "X", ...
    "yLabel", "Y", "zLabel", "", "xScale", "linear", ...
    "yScale", "linear", "zScale", "linear", "xDir", "normal", ...
    "yDir", "normal", "zDir", "normal", "xLim", [0 2], ...
    "yLim", [-1 3], "zLim", [0 1], "xTick", 0:2, ...
    "yTick", -1:3, "zTick", [], "xTickLabel", string(0:2), ...
    "yTickLabel", string(-1:3), "zTickLabel", strings(0, 1), ...
    "cLim", [0 1], "colormap", []);
object = struct("type", "line", "displayName", "Signal", ...
    "x", (0:2).', "y", [-1; 1; 2], "z", [], "c", [], "alpha", [], ...
    "style", struct(), "metadata", struct("handleVisibility", "on"));
data = struct("axes", axesData, "objects", object, ...
    "warnings", strings(0, 1));
end
