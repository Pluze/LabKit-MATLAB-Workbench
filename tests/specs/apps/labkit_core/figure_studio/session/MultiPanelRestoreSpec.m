classdef MultiPanelRestoreSpec < matlab.unittest.TestCase
    % MULTIPANELRESTORESPEC Regression: session reconstruction must retain every source panel and restore the requested active panel.

    methods (Test, TestTags = {'Contract:state', 'Env:hidden-gui'})
        function importsUiAxesWithIndependentLeftAndRightRulers(testCase)
            fig = uifigure(Visible="off");
            cleanup = onCleanup(@() delete(fig));
            ax = uiaxes(fig);
            yyaxis(ax, "left");
            plot(ax, 1:3, [1 2 3]); ylim(ax, [0 4]); ylabel(ax, "Force (N)");
            yyaxis(ax, "right");
            plot(ax, 1:3, [100 200 300]); ylim(ax, [0 400]); ylabel(ax, "Travel (mm)");
            [project, ~] = figure_studio.launchRequest({"axes", ax});
            context = struct("setResource", @ignoreResource);

            session = figure_studio.createSession(project, context);

            rulers = session.cache.plotData.axes.yAxes;
            testCase.verifyEqual(rulers(1).limits, [0 4]);
            testCase.verifyEqual(rulers(2).limits, [0 400]);
            testCase.verifyEqual(rulers(1).label, "Force (N)");
            testCase.verifyEqual(rulers(2).label, "Travel (mm)");
            objects = session.cache.plotData.objects;
            sides = arrayfun(@(value) value.metadata.yAxisSide, objects);
            testCase.verifyEqual(sort(sides), ["left"; "right"]);
            testCase.verifyEqual(sort(objects(sides == "right").y(:)), [100; 200; 300]);
            testCase.verifyEqual(string(ax.YAxisLocation), "right");
            testCase.verifyEqual(ax.YAxis(1).Limits, [0 4]);
            testCase.verifyEmpty(session.cache.sourceAxes);
            clear cleanup
        end
    end

    methods (Test, TestTags = {'Contract:state', 'Env:headless'})
        function provesMultiPanelRestore(testCase)
            cleanup = onCleanup(@() close(findall(groot, "Type", "figure")));
            folder = string(tempname);
            mkdir(folder);
            folderCleanup = onCleanup(@() rmdir(folder, "s"));
            path = fullfile(folder, "multi-panel.fig");
            sourceFigure = figure(Visible="off");
            tiled = tiledlayout(sourceFigure, 1, 2);
            first = nexttile(tiled);
            plot(first, 0:2, 1:3);
            title(first, "First panel");
            second = nexttile(tiled);
            plot(second, 0:2, 3:-1:1);
            title(second, "Second panel");
            savefig(sourceFigure, path);
            close(sourceFigure);
            project = figure_studio.initialData();
            project.inputs.sources = labkit.app.source.record( ...
                "figure-1", "figure", path);
            project.annotations.panelIndex = 2;
            context = struct("setResource", @ignoreResource);

            session = figure_studio.createSession(project, context);

            testCase.verifyNumElements(session.editor.document.panels, 2);
            testCase.verifyEqual(session.editor.activePanelId, "panel-2");
            testCase.verifyEqual(session.editor.selectedPanelIds, "panel-2");
            testCase.verifyEqual(session.selection.panel, "Panel 2 — Second panel");
            testCase.verifyEqual(session.cache.plotData.axes.title, ...
                "Second panel");
            testCase.verifyEqual(string( ...
                session.cache.sourceAxes.Title.String), "Second panel");
            clear folderCleanup cleanup
        end
    end
end

function ignoreResource(varargin)
end
