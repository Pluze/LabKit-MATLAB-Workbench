classdef FigureStudioSourceAxesGuiTest < matlab.unittest.TestCase
    %FIGURESTUDIOSOURCEAXESGUITEST Exercise Figure Studio source import paths.

    methods (Test, TestTags = {'GUI', 'Structural', 'Workflow', 'RouteFeature:axes-presentation'})
        function acceptsPopoutAxesHandoff(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            sourceFig = figure('Visible', 'off');
            sourceAx = axes('Parent', sourceFig);
            plot(sourceAx, 1:3, [1 4 2], 'DisplayName', 'probe');
            title(sourceAx, 'Probe');
            sourceAx.FontSize = 28;
            sourceAx.LineWidth = 4;
            pbaspect(sourceAx, [2 1 1]);
            [initialProject, ~] = figure_studio.launchRequest({"axes", sourceAx});
            runtime = labkit.app.internal.RuntimeFactory.createMatlab( ...
                figure_studio.definition(), initialProject);
            runtimeCleanup = onCleanup(@() runtime.close());
            fig = runtime.figureHandle();
            ax = findall(fig, "Tag", "preview.main");

            testCase.verifyNotEmpty(ax.Children);
            testCase.verifyEqual(runtime.State.session.cache.currentSource, "Popout axes");
            testCase.verifyEmpty(findall(ax, "Type", "image"));
            testCase.verifyEqual(string(ax.Title.String), "Probe");
            testCase.verifyEqual(string(findall(fig, "Tag", "exportCurrent").Enable), "on");
            testCase.verifyEqual( ...
                runtime.State.project.parameters.aspectPreset, "Reference");
            clear runtimeCleanup cleanup;
        end

        function keepsNativeBoxplotForFigAndHandoff(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            sourceFig = figure('Visible', 'off', 'Color', 'w');
            sourceAx = axes('Parent', sourceFig);
            drawGroupedBoxPlot(sourceAx);
            expectedLineCount = numel(findall(sourceAx, 'Type', 'line'));
            testCase.verifyGreaterThan(expectedLineCount, 10);

            folder = string(tempname);
            mkdir(folder);
            folderCleanup = onCleanup(@() removeTempFolder(folder));
            figPath = fullfile(folder, "grouped-boxplot.fig");
            savefig(sourceFig, figPath);

            fromFile = labkit.app.internal.RuntimeFactory.createMatlab( ...
                figure_studio.definition());
            fileRuntimeCleanup = onCleanup(@() fromFile.close());
            fromFile.applyFileSelection("figFiles", figPath, 1);
            assertNativeBoxPlot(testCase, ...
                fromFile.State.session.cache.sourceAxes, expectedLineCount, ...
                "Opening a FIG should preserve the native boxplot resource.");

            [handoffProject, ~] = figure_studio.launchRequest({"axes", sourceAx});
            fromHandoff = labkit.app.internal.RuntimeFactory.createMatlab( ...
                figure_studio.definition(), handoffProject);
            handoffRuntimeCleanup = onCleanup(@() fromHandoff.close());
            assertNativeBoxPlot(testCase, ...
                fromHandoff.State.session.cache.sourceAxes, expectedLineCount, ...
                "Sending axes to Studio should preserve the native boxplot resource.");
            clear handoffRuntimeCleanup fileRuntimeCleanup folderCleanup cleanup;
        end

        function preservesImageOverlaysForFigAndHandoff(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            sourceFig = figure('Visible', 'off', 'Color', 'w');
            sourceAx = axes('Parent', sourceFig);
            drawImageOverlayProbe(sourceAx);
            folder = string(tempname);
            mkdir(folder);
            folderCleanup = onCleanup(@() removeTempFolder(folder));
            figPath = fullfile(folder, "image-overlay.fig");
            savefig(sourceFig, figPath);

            fromFile = labkit.app.internal.RuntimeFactory.createMatlab( ...
                figure_studio.definition());
            fileRuntimeCleanup = onCleanup(@() fromFile.close());
            fromFile.applyFileSelection("figFiles", figPath, 1);
            assertImageOverlaysInFront(testCase, ...
                findall(fromFile.figureHandle(), 'Tag', 'preview.main'), ...
                "Opening a FIG must leave overlays above its image.");

            [handoffProject, ~] = figure_studio.launchRequest({"axes", sourceAx});
            fromHandoff = labkit.app.internal.RuntimeFactory.createMatlab( ...
                figure_studio.definition(), handoffProject);
            handoffRuntimeCleanup = onCleanup(@() fromHandoff.close());
            assertImageOverlaysInFront(testCase, ...
                findall(fromHandoff.figureHandle(), 'Tag', 'preview.main'), ...
                "Sending axes must leave overlays above its image.");
            clear handoffRuntimeCleanup fileRuntimeCleanup folderCleanup cleanup;
        end

        function editsOneSubplotFromMixedFig(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            folder = string(tempname);
            mkdir(folder);
            folderCleanup = onCleanup(@() removeTempFolder(folder));
            figPath = fullfile(folder, "mixed-panels.fig");
            saveMixedPanelFigure(figPath);

            runtime = labkit.app.internal.RuntimeFactory.createMatlab( ...
                figure_studio.definition());
            runtimeCleanup = onCleanup(@() runtime.close());
            runtime.applyFileSelection("figFiles", figPath, 1);
            choices = string(findall(runtime.figureHandle(), "Tag", "sourcePanel").Items);
            testCase.verifyEqual(numel(choices), 4);
            runtime.applyControlValue("sourcePanel", choices(4));
            selectedAxes = runtime.State.session.cache.sourceAxes;
            testCase.verifyEqual(string(selectedAxes.Title.String), "Panel D");
            testCase.verifyEqual(numel(findall(selectedAxes, "Type", "line")), 1);
            clear runtimeCleanup folderCleanup cleanup;
        end
    end
end

function drawGroupedBoxPlot(ax)
summaries = [1.1 1.4 1.7 2.2 2.8 3.1; 5.6 6.1 6.7 7.2 7.8 8.4];
hold(ax, 'on');
for groupIndex = 1:size(summaries, 1)
    drawNativeBoxGroup(ax, groupIndex, summaries(groupIndex, :));
end
text(ax, 1.5, 8.7, 'Native group probe', 'HorizontalAlignment', 'center');
hold(ax, 'off');
end

function drawImageOverlayProbe(ax)
image(ax, 'CData', uint8(80 .* ones(12, 16, 3)), 'XData', [0 1], 'YData', [0 1]);
hold(ax, 'on');
line(ax, [0.1 0.9], [0.2 0.8], 'Color', [1 0 0], 'LineWidth', 3);
text(ax, 0.5, 0.6, 'overlay', 'Color', [1 1 1], 'HorizontalAlignment', 'center');
hold(ax, 'off');
end

function assertImageOverlaysInFront(testCase, ax, message)
types = string({ax.Children.Type});
imageIndex = find(types == "image", 1, 'first');
lineIndex = find(types == "line", 1, 'first');
textIndex = find(types == "text", 1, 'first');
testCase.verifyNotEmpty(imageIndex, message);
testCase.verifyNotEmpty(lineIndex, message);
testCase.verifyNotEmpty(textIndex, message);
testCase.verifyGreaterThan(imageIndex, lineIndex, message);
testCase.verifyGreaterThan(imageIndex, textIndex, message);
end

function saveMixedPanelFigure(filepath)
fig = figure('Visible', 'off', 'Color', 'w');
cleanup = onCleanup(@() delete(fig));
layout = tiledlayout(fig, 2, 2);
for k = 1:4
    ax = nexttile(layout);
    plot(ax, 1:3, k + [0 1 0]);
    title(ax, "Panel " + char('A' + k - 1));
end
savefig(fig, filepath);
end

function drawNativeBoxGroup(ax, x, values)
group = hggroup('Parent', ax, 'Tag', sprintf('boxplot-group-%d', x));
width = 0.25;
common = {'Color', [0 0.4470 0.7410], 'LineWidth', 1.5};
line('Parent', group, 'XData', [x-width x+width x+width x-width x-width], ...
    'YData', [values(2) values(2) values(4) values(4) values(2)], common{:});
line('Parent', group, 'XData', [x-width x+width], 'YData', [values(3) values(3)], common{:});
line('Parent', group, 'XData', [x x], 'YData', [values(1) values(2)], common{:});
line('Parent', group, 'XData', [x x], 'YData', [values(4) values(5)], common{:});
line('Parent', group, 'XData', [x-width/2 x+width/2], 'YData', [values(1) values(1)], common{:});
line('Parent', group, 'XData', [x-width/2 x+width/2], 'YData', [values(5) values(5)], common{:});
line('Parent', group, 'XData', x, 'YData', values(6), common{:}, ...
    'LineStyle', 'none', 'Marker', '+');
end

function assertNativeBoxPlot(testCase, preview, expectedLineCount, message)
testCase.verifyNotEmpty(preview);
testCase.verifyGreaterThanOrEqual(numel(findall(preview, 'Type', 'line')), expectedLineCount, message);
testCase.verifyTrue(any(string({findall(preview, 'Type', 'text').String}) == "Native group probe"), message);
end

function removeTempFolder(folder)
if isfolder(folder)
    rmdir(folder, 's');
end
end
