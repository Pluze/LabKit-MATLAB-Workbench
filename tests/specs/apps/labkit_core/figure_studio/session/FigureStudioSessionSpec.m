classdef FigureStudioSessionSpec < matlab.unittest.TestCase
    % FIGURESTUDIOSESSIONSPEC Saved plot state reconstruction contract.

    methods (Test, TestTags = {'Contract:state', 'Env:headless'})
        function derivesEditableAxesStateFromASavedPlot(testCase)
            cleanup = onCleanup(@() close(findall(groot, "Type", "figure")));
            fig = figure(Visible="off");
            ax = axes(Parent=fig);
            plot(ax, 1:3, [4 2 5]);
            title(ax, "Stored title");
            xlabel(ax, "Stored X");
            ylabel(ax, "Stored Y");
            project = figure_studio.initialData();
            project.annotations.embeddedPlot = ...
                figure_studio.resultFiles.extractAxesData(ax);
            project.annotations.limitOverrides.xLim = [-100 100];
            project.parameters.style.tickDirection = "both";

            session = figure_studio.createSession(project, ...
                labkittest.createCallbackContext(struct()));

            testCase.verifyEqual(session.cache.plotData.axes.xLim, [-100 100]);
            testCase.verifyEqual(session.cache.limitState.xMin, -100);
            testCase.verifyEqual(session.cache.limitState.xMax, 100);
            testCase.verifyEqual(session.cache.limitState.title, "Stored title");
            testCase.verifyEqual(session.cache.limitState.xLabel, "Stored X");
            testCase.verifyEqual(session.cache.limitState.yLabel, "Stored Y");
            testCase.verifyEqual(session.cache.limitState.tickDir, "both");
            testCase.verifyEqual(session.cache.viewRevision, 1);
            testCase.verifyEmpty(session.cache.sourceAxes);
            clear cleanup
        end
    end
end
