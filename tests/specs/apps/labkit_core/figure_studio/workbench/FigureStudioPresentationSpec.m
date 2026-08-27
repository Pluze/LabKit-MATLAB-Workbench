classdef FigureStudioPresentationSpec < matlab.unittest.TestCase
    %FIGURESTUDIOPRESENTATIONSPEC Specify figure import, styling, and export controls.

    methods (Test, TestTags = {'Contract:presentation', 'Env:headless'})
        function declaresFigureSourceStyleAndExportControls(testCase)
            plan = labkittest.inspectDefinition(figure_studio.definition());
            ids = string({plan.Nodes.Id});

            testCase.verifyTrue(all(ismember( ...
                ["preview" "outputFolder" "exportCurrent"], ids)));
            testCase.verifyFalse(any(ids == "appLog"));
        end

        function coordinateDomainRefitsWhileStyleAndAnnotationsPreserve(testCase)
            state = stateFixture();
            original = revisionFor(state);

            styled = state;
            styled.project.parameters.style.tickFontSize = 24;
            styled.session.cache.plotData.objects(1).style.LineWidth = 4;
            styled.session.cache.plotData.axes.yAxes(1).tickLabels = "styled";
            styled.session.cache.plotData.axes.yAxes(1).color = [1 0 0];
            testCase.verifyEqual( ...
                revisionFor(styled), original);

            moved = state;
            moved.session.cache.plotData.objects(1).x = [4 5 6];
            testCase.verifyEqual( ...
                revisionFor(moved), original);

            limited = state;
            limited.session.cache.plotData.axes.xLim = [-2 8];
            testCase.verifyNotEqual( ...
                revisionFor(limited), original);

            changedPanel = state;
            changedPanel.session.editor.activePanelId = "panel-2";
            testCase.verifyNotEqual( ...
                revisionFor(changedPanel), ...
                original);
        end
    end
end

function revision = revisionFor(state)
revision = figure_studio.workbench.viewportRevision( ...
    state.project.inputs.sources, ...
    state.session.editor.activePanelId, ...
    state.session.cache.plotData, ...
    state.session.cache.viewRevision);
end

function state = stateFixture()
project = figure_studio.initialData();
project.inputs.sources = struct("id", "figure-a", "role", "figure", ...
    "path", "ignored.fig");
plotData = struct("axes", struct( ...
    "xScale", "linear", "xDir", "normal", "xLim", [0 10], ...
    "yScale", "linear", "yDir", "normal", "yLim", [0 5], ...
    "zScale", "linear", "zDir", "normal", "zLim", [0 1], ...
    "yAxes", struct("side", "right", "scale", "linear", ...
        "direction", "normal", "limits", [0 5], ...
        "tickLabels", "original", "color", [0 0 0])), ...
    "objects", struct("x", [1 2 3], "style", struct("LineWidth", 1)));
state = struct("project", project, "session", struct( ...
    "editor", struct("activePanelId", "panel-1"), ...
    "cache", struct("plotData", plotData, "viewRevision", 1)));
end
