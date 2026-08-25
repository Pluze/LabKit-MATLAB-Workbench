classdef MultiPanelRestoreSpec < matlab.unittest.TestCase
    % MULTIPANELRESTORESPEC Regression: session reconstruction must retain every source panel and restore the requested active panel.

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
