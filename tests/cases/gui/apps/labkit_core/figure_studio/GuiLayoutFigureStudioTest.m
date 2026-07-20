classdef GuiLayoutFigureStudioTest < matlab.unittest.TestCase
    %GUILAYOUTFIGURESTUDIOTEST Verify Figure Studio launch and controls.

    methods (Test, TestTags = {'GUI', 'Structural', 'Workflow'})
        function figure_studio_launches_with_style_library(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            folder = string(tempname);
            mkdir(folder);
            folderCleanup = onCleanup(@() removeTempFolder(folder));
            figPath = fullfile(folder, 'probe.fig');
            saveProbeFigure(figPath);
            pngPath = fullfile(folder, 'styled-probe.png');
            backend = struct( ...
                "chooseOutputFile", @(~, ~) ...
                    labkit.app.dialog.Choice(pngPath), ...
                "chooseOutputFolder", @(~) ...
                    labkit.app.dialog.Choice(folder), ...
                "alert", @(~, ~) []);
            runtime = labkit.app.internal.RuntimeFactory.createMatlab( ...
                figure_studio.definition(), [], backend);
            runtimeCleanup = onCleanup(@() runtime.close());
            fig = runtime.figureHandle();
            assertFigureStudioLayout(h, fig);

            preset = findall(fig, "Tag", "stylePreset");
            testCase.verifyEqual(string(preset.Items), ...
                ["LabKit figure", "FIG default"]);
            style = runtime.State.project.parameters.style;
            testCase.verifyEqual(style.baseFontSize, 36);
            testCase.verifyEqual(style.dataLineWidth, 3);
            testCase.verifyEqual(style.axesLineWidth, 3);
            runtime.applyControlValue("baseFontSize", 24);
            style = runtime.State.project.parameters.style;
            testCase.verifyEqual([style.baseFontSize, style.titleFontSize, ...
                style.labelFontSize, style.tickFontSize], [24 24 24 24]);
            runtime.applyControlValue("titleFontSize", 32);
            testCase.verifyEqual( ...
                runtime.State.project.parameters.style.titleFontSize, 32);
            runtime.applyControlValue("aspectPreset", "Custom");
            runtime.applyControlValue("canvasWidth", 1550);
            runtime.applyControlValue("canvasHeight", 777);
            style = runtime.State.project.parameters.style;
            testCase.verifyEqual( ...
                runtime.State.project.parameters.aspectPreset, "Custom");
            testCase.verifyEqual( ...
                [style.canvasWidth style.canvasHeight], [1550 777]);

            runtime.applyFileSelection("figFiles", figPath, 1);
            testCase.verifyNotEmpty(runtime.State.session.cache.plotData);
            testCase.verifyFalse(containsGraphicsHandle( ...
                runtime.State.project));
            ax = findall(fig, "Tag", "preview.main");
            testCase.verifyNotEmpty(ax.Children);
            testCase.verifyEqual(string( ...
                findall(fig, "Tag", "exportCurrent").Enable), "on");
            testCase.verifyFalse(contains( ...
                join(string(ax.Title.String), " "), " | file "));
            testCase.verifyTrue(isappdata( ...
                ax, 'labkitFigureStudioCanvasFrame'));
            frameBefore = getappdata( ...
                ax, 'labkitFigureStudioCanvasFrame');
            fig.Position(3:4) = max( ...
                [900 620], fig.Position(3:4) - [420 260]);
            pause(0.8);
            drawnow;
            frameAfter = getappdata( ...
                ax, 'labkitFigureStudioCanvasFrame');
            testCase.verifyTrue(isfield(frameAfter, 'scale'));
            testCase.verifyLessThanOrEqual( ...
                frameAfter.scale, frameBefore.scale);
            testCase.verifyEqual(frameAfter.ratio, ...
                frameBefore.ratio, 'AbsTol', 1e-12);

            runtime.invokeAction("exportPng");
            testCase.verifyTrue(isfile(pngPath));
            testCase.verifyTrue(isfile( ...
                fullfile(folder, 'figure_studio.labkit.json')));
            runtime.invokeAction("chooseOutputFolder");
            runtime.invokeAction("exportCurrent");
            packagePath = string( ...
                runtime.State.project.results.lastExport.path);
            testCase.verifyTrue(startsWith(packagePath, folder));
            testCase.verifyNotEqual(packagePath, folder);
            testCase.verifyTrue(isfile( ...
                fullfile(packagePath, 'plot_data.mat')));
            testCase.verifyTrue(isfile( ...
                fullfile(packagePath, 'recreate_plot.m')));
            testCase.verifyTrue(isfile( ...
                fullfile(packagePath, 'figure_studio.labkit.json')));
            assertNoDuplicateSpecIds(fig);
            clear runtimeCleanup folderCleanup cleanup;
        end

        function figure_studio_accepts_popout_axes_handoff(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            sourceFig = figure('Visible', 'off');
            sourceAx = axes('Parent', sourceFig);
            plot(sourceAx, 1:3, [1 4 2], 'DisplayName', 'probe');
            title(sourceAx, 'Probe');
            pbaspect(sourceAx, [2 1 1]);
            [initialProject, ~] = figure_studio.launchRequest( ...
                {"axes", sourceAx});
            runtime = labkit.app.internal.RuntimeFactory.createMatlab( ...
                figure_studio.definition(), initialProject);
            runtimeCleanup = onCleanup(@() runtime.close());
            fig = runtime.figureHandle();
            ax = findall(fig, "Tag", "preview.main");
            testCase.verifyNotEmpty(ax.Children);
            testCase.verifyEqual(string( ...
                findall(fig, "Tag", "exportCurrent").Enable), "on");
            style = runtime.State.project.parameters.style;
            canvasRatio = double(style.canvasWidth) / ...
                double(style.canvasHeight);
            testCase.verifyEqual(canvasRatio, 2, 'AbsTol', 0.02);
            testCase.verifyEqual( ...
                runtime.State.project.parameters.aspectPreset, "Custom");

            folder = string(tempname);
            mkdir(folder);
            folderCleanup = onCleanup(@() removeTempFolder(folder));
            projectPath = fullfile( ...
                folder, 'figure-studio-project.mat');
            runtime.saveProject(runtime.State, projectPath);
            saved = load(projectPath, 'labkitProject');
            testCase.verifyEqual(saved.labkitProject.app.payloadVersion, 1);
            testCase.verifyFalse(isfield( ...
                saved.labkitProject.payload, 'session'));
            testCase.verifyFalse(containsGraphicsHandle( ...
                saved.labkitProject.payload));
            testCase.verifyNotEmpty( ...
                saved.labkitProject.payload.annotations.embeddedPlot);
            runtime.restoreProject(projectPath);
            testCase.verifyNotEmpty( ...
                runtime.State.session.cache.plotData);
            testCase.verifyNotEmpty(ax.Children);
            clear runtimeCleanup folderCleanup cleanup;
        end

        function figure_studio_waits_for_stable_preview_canvas(~)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            fig = uifigure('Visible', 'off', ...
                'Position', [100 100 1200 800]);
            grid = uigridlayout(fig, [3 3]);
            ax = uiaxes(grid);
            ax.Layout.Row = 2;
            ax.Layout.Column = 2;
            plot(ax, linspace(0, 30, 200), ...
                sin(linspace(0, 30, 200)));

            style = figure_studio.styleLibrary.styleForPreset( ...
                "LabKit figure");
            style.previewScale = true;
            figure_studio.resultFiles.applyFigureStyle(ax, style);

            frame = getappdata(ax, 'labkitFigureStudioCanvasFrame');
            assert(ax.Layout.Row == 2 && ax.Layout.Column == 2);
            if isfield(frame, 'pixelPosition')
                frameIsStable = frame.pixelPosition(3) > 100 && ...
                    frame.pixelPosition(4) > 100;
            else
                frameIsStable = frame.position(3) > 0.5 && ...
                    frame.position(4) > 0.5;
            end
            assert(frame.scale > 0.5 && frameIsStable);
        end

        function popout_send_to_studio_copies_plot_content(~)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            sourceFig = figure('Visible', 'off', 'Name', 'Source Plot');
            sourceAx = axes('Parent', sourceFig);
            plot(sourceAx, 1:3, [2 1 4], 'DisplayName', 'source');
            title(sourceAx, 'Source Plot');

            labkit.app.plot.enablePopout(sourceAx);
            menu = findall(sourceAx.ContextMenu, 'Type', 'uimenu', ...
                'Tag', 'labkitAxesPopoutMenu');
            menu(1).MenuSelectedFcn(menu(1), []);
            popoutFig = findall(groot, 'Type', 'figure', ...
                'Name', 'Source Plot');
            popoutFig = popoutFig(1);
            hookCleanup = onCleanup(@() removeStudioHook());
            setappdata(groot, 'labkitFigureStudioLauncher', ...
                @(ax) labkit_FigureStudio_app("axes", ax));
            studioTool = findall(popoutFig, ...
                'Tag', 'labkitAxesPopoutStudioTool');
            assert(~isempty(studioTool));
            h.invokeCallback(studioTool(1), 'Callback');
            drawnow;

            studioFig = figureStudioFigures();
            assert(~isempty(studioFig));
            preview = findall(studioFig(1), "Tag", "preview.main");
            export = findall(studioFig(1), "Tag", "exportCurrent");
            assert(~isempty(preview.Children) && ...
                string(export.Enable) == "on");
            clear hookCleanup cleanup;
        end
    end
end

function assertFigureStudioLayout(h, fig)
h.assertStartupSucceeded(fig);
ids = ["figFiles", "currentSource", "statusSummary", "stylePreset", ...
    "aspectPreset", "canvasWidth", "canvasHeight", "exportScale", ...
    "boundaryLines", "baseFontSize", "titleFontSize", "labelFontSize", ...
    "tickFontSize", "dataLineWidth", "axesLineWidth", "gridAlpha", ...
    "gridVisible", "outputFolder", "saveFig", ...
    "exportPng", "exportJpg", "exportSvg", "chooseOutputFolder", ...
    "exportCurrent", ...
    "preview.main"];
for id = ids
    assert(numel(findall(fig, "Tag", id)) == 1, ...
        "Missing Figure Studio semantic target: %s.", id);
end
tabs = findall(fig, "Type", "uitab");
assert(isequal(sort(string({tabs.Title})), ...
    sort(["Figures", "Export", "Log"])));
end

function removeStudioHook()
if isappdata(groot, 'labkitFigureStudioLauncher')
    rmappdata(groot, 'labkitFigureStudioLauncher');
end
end

function figures = figureStudioFigures()
allFigures = findall(groot, 'Type', 'figure');
keep = false(size(allFigures));
for k = 1:numel(allFigures)
    keep(k) = contains(string(allFigures(k).Name), "Figure Studio");
end
figures = allFigures(keep);
end

function saveProbeFigure(filepath)
f = figure('Visible', 'off');
cleanup = onCleanup(@() delete(f));
ax = axes('Parent', f);
plot(ax, 1:4, [1 3 2 4], 'DisplayName', 'probe');
title(ax, 'Probe');
savefig(f, filepath);
end

function removeTempFolder(folder)
if isfolder(folder)
    rmdir(folder, 's');
end
end

function tf = containsGraphicsHandle(value)
tf = isa(value, 'matlab.graphics.Graphics');
if tf
    return;
end
if isstruct(value)
    names = fieldnames(value);
    for index = 1:numel(value)
        for name = names.'
            if containsGraphicsHandle(value(index).(name{1}))
                tf = true;
                return;
            end
        end
    end
elseif iscell(value)
    for index = 1:numel(value)
        if containsGraphicsHandle(value{index})
            tf = true;
            return;
        end
    end
end
end

function assertNoDuplicateSpecIds(fig)
tags = string(get(findall(fig), 'Tag'));
tags = tags(strlength(tags) > 0);
[uniqueTags, ~, group] = unique(tags);
counts = accumarray(group, 1);
duplicateTags = uniqueTags(counts > 1);
assert(~any(duplicateTags == "figures"));
end
