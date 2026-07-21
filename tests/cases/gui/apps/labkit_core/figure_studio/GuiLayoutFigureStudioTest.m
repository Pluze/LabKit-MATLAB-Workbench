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
            testCase.verifyEqual(style.baseFontSize, 20);
            testCase.verifyEqual(style.titleFontSize, 60);
            testCase.verifyEqual(style.labelFontSize, 72);
            testCase.verifyEqual(style.tickFontSize, 60);
            testCase.verifyEqual(style.annotationFontSize, 54);
            testCase.verifyEqual(style.legendFontSize, 64);
            testCase.verifyEqual(style.dataLineWidth, 6.0);
            testCase.verifyEqual(style.uncertaintyLineWidth, 4.0);
            testCase.verifyEqual(style.boundaryLineWidth, 2.5);
            testCase.verifyEqual(style.referenceLineWidth, 4.0);
            testCase.verifyEqual(style.axesLineWidth, 2.4);
            testCase.verifyEqual(style.axesPosition, ...
                [0.185 0.17 0.795 0.78]);
            testCase.verifyEqual([style.canvasWidth style.canvasHeight], ...
                [1600 1333]);
            testCase.verifyEqual( ...
                [style.referenceCanvasWidth style.referenceCanvasHeight], ...
                [1600 1333]);
            testCase.verifyEqual( ...
                runtime.State.project.parameters.aspectPreset, "6:5");
            runtime.applyControlValue("baseFontSize", 24);
            style = runtime.State.project.parameters.style;
            testCase.verifyEqual([style.baseFontSize, style.titleFontSize, ...
                style.labelFontSize, style.tickFontSize], [24 24 24 24]);
            runtime.applyControlValue("titleFontSize", 32);
            testCase.verifyEqual( ...
                runtime.State.project.parameters.style.titleFontSize, 32);
            previewPosition = findall(fig, "Tag", "preview.main").Position;
            runtime.applyControlValue("aspectPreset", "16:9");
            runtime.applyControlValue("canvasSize", "1200 px");
            style = runtime.State.project.parameters.style;
            testCase.verifyEqual( ...
                runtime.State.project.parameters.aspectPreset, "16:9");
            testCase.verifyEqual( ...
                [style.canvasWidth style.canvasHeight], [1200 675]);
            testCase.verifyEqual(findall(fig, "Tag", "preview.main").Position, ...
                previewPosition, ...
                "Export canvas choices must not replace the preview plot allocation.");

            runtime.applyFileSelection("figFiles", figPath, 1);
            testCase.verifyNotEmpty(runtime.State.session.cache.plotData);
            testCase.verifyFalse(containsGraphicsHandle( ...
                runtime.State.project));
            ax = findall(fig, "Tag", "preview.main");
            testCase.verifyNotEmpty(ax.Children);
            testCase.verifyNumElements(findall(ax, "Type", "image"), 1, ...
                "The workbench preview must be the export-canvas rendering.");
            previewInfo = getappdata(ax, 'labkitFigureStudioExportPreview');
            testCase.verifyEqual(previewInfo.canvas, [1200 675]);
            testCase.verifyEqual(string( ...
                findall(fig, "Tag", "exportCurrent").Enable), "on");
            testCase.verifyFalse(contains( ...
                join(string(ax.Title.String), " "), " | file "));
            originalLimits = runtime.State.session.cache.plotData.axes.xLim;
            runtime.invokeAction("recalculateLimits");
            testCase.verifyNotEqual( ...
                runtime.State.session.cache.plotData.axes.xLim, originalLimits, ...
                "The explicit limit action should recover the visible data extent.");

            runtime.invokeAction("exportPng");
            testCase.verifyTrue(isfile(pngPath));
            pngInfo = imfinfo(pngPath);
            testCase.verifyEqual(double(pngInfo.Width) / double(pngInfo.Height), ...
                16 / 9, 'AbsTol', 0.01, ...
                "Quick raster export must retain the selected canvas aspect.");
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
            sourceAx.FontSize = 28;
            sourceAx.LineWidth = 4;
            pbaspect(sourceAx, [2 1 1]);
            [initialProject, ~] = figure_studio.launchRequest( ...
                {"axes", sourceAx});
            testCase.verifyEqual( ...
                initialProject.parameters.preset, "LabKit figure");
            testCase.verifyEqual( ...
                initialProject.parameters.style.tickFontSize, 40);
            testCase.verifyEqual( ...
                initialProject.parameters.style.axesLineWidth, 2.0);
            testCase.verifyEqual( ...
                initialProject.annotations.sourceDefaultStyle.tickFontSize, ...
                28);
            testCase.verifyEqual( ...
                initialProject.annotations.sourceDefaultStyle.axesLineWidth, ...
                4);
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
            testCase.verifyEqual(canvasRatio, 6 / 5, 'AbsTol', 0.02);
            testCase.verifyEqual( ...
                runtime.State.project.parameters.aspectPreset, "6:5");

            folder = string(tempname);
            mkdir(folder);
            folderCleanup = onCleanup(@() removeTempFolder(folder));
            projectPath = fullfile( ...
                folder, 'figure-studio-project.mat');
            runtime.saveProject(runtime.State, projectPath);
            saved = load(projectPath, 'labkitProject');
            testCase.verifyEqual(saved.labkitProject.app.payloadVersion, 4);
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

        function figure_studio_keeps_native_boxplot_for_fig_and_handoff(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            sourceFig = figure('Visible', 'off', 'Color', 'w');
            sourceAx = axes('Parent', sourceFig);
            drawGroupedBoxPlot(sourceAx);
            expectedLineCount = numel(findall(sourceAx, 'Type', 'line'));
            testCase.verifyGreaterThan(expectedLineCount, 10, ...
                "The synthetic boxplot fixture must expose grouped box lines.");

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
            [exportFig, exportAxes] = ...
                figure_studio.resultFiles.createStyledFigure( ...
                fromFile.State.session.cache.plotData, ...
                fromFile.State.project.parameters.style, ...
                fromFile.State.session.cache.sourceAxes);
            exportCleanup = onCleanup(@() delete(exportFig));
            testCase.verifyTrue(hasNativeGroup(exportAxes), ...
                "FIG export should retain MATLAB's grouped boxplot object.");

            [handoffProject, ~] = figure_studio.launchRequest( ...
                {"axes", sourceAx});
            fromHandoff = labkit.app.internal.RuntimeFactory.createMatlab( ...
                figure_studio.definition(), handoffProject);
            handoffRuntimeCleanup = onCleanup(@() fromHandoff.close());
            assertNativeBoxPlot(testCase, ...
                fromHandoff.State.session.cache.sourceAxes, expectedLineCount, ...
                "Sending axes to Studio should preserve the native boxplot resource.");
            testCase.verifyFalse(containsGraphicsHandle( ...
                fromHandoff.State.project), ...
                "The native source clone must stay transient, never in a project.");
            clear exportCleanup handoffRuntimeCleanup fileRuntimeCleanup folderCleanup cleanup;
        end

        function figure_studio_edits_one_subplot_from_a_mixed_fig(testCase)
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
            choices = string(findall(runtime.figureHandle(), ...
                "Tag", "sourcePanel").Items);
            testCase.verifyEqual(numel(choices), 4);
            testCase.verifyEqual(runtime.State.session.selection.panel, ...
                choices(1));
            selectedAxes = runtime.State.session.cache.sourceAxes;
            testCase.verifyEqual(string(selectedAxes.Title.String), "Panel A");

            runtime.applyControlValue("sourcePanel", choices(4));
            testCase.verifyEqual(runtime.State.project.annotations.panelIndex, 4);
            selectedAxes = runtime.State.session.cache.sourceAxes;
            testCase.verifyEqual(string(selectedAxes.Title.String), "Panel D");
            testCase.verifyEqual(string(selectedAxes.XLabel.String), "x-D");
            testCase.verifyEqual(string(selectedAxes.YLabel.String), "y-D");
            testCase.verifyEqual(numel(findall(selectedAxes, "Type", "line")), 1, ...
                "Only the selected subplot may be copied into Studio.");
            clear runtimeCleanup folderCleanup cleanup;
        end

        function figure_studio_renders_a_stable_export_canvas_preview(testCase)
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
            source = figure('Visible', 'off', 'Color', 'w');
            sourceAx = axes('Parent', source);
            plot(sourceAx, linspace(0, 30, 200), ...
                sin(linspace(0, 30, 200)));
            style = figure_studio.styleLibrary.styleForPreset( ...
                "LabKit figure");
            data = figure_studio.resultFiles.extractAxesData(sourceAx);
            figure_studio.sourceAxes.drawPreview(struct("main", ax), ...
                struct("plotData", data, "sourceAxes", sourceAx, ...
                "style", style, "preview", true));

            preview = findall(ax, "Type", "image");
            testCase.verifyNumElements(preview, 1);
            testCase.verifyEqual(getappdata( ...
                ax, 'labkitFigureStudioExportPreview').canvas, [1600 1333]);
            pixelsBefore = preview.CData;
            fig.Position(3:4) = [760 540];
            drawnow;
            testCase.verifyEqual(preview.CData, pixelsBefore, ...
                "Workspace resize must not recompute text or stroke proportions.");
            testCase.verifyEqual(diff(ax.XLim) / diff(ax.YLim), ...
                1600 / 1333, 'AbsTol', 0.01);
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
ids = ["figFiles", "currentSource", "sourcePanel", "statusSummary", "stylePreset", ...
    "aspectPreset", "canvasSize", "exportScale", "recalculateLimits", ...
    "boundaryLines", "baseFontSize", "titleFontSize", "labelFontSize", ...
    "tickFontSize", "annotationFontSize", "xTickLabelAngle", ...
    "dataLineWidth", "uncertaintyLineWidth", ...
    "boundaryLineWidth", ...
    "referenceLineWidth", "axesLineWidth", "gridAlpha", ...
    "gridVisible", "legendVisible", "legendLocation", ...
    "legendFontSize", "legendNumColumns", "legendBox", ...
    "outputFolder", "saveFig", ...
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
ax.XLim = [1.75 2.25];
savefig(f, filepath);
end

function saveMixedPanelFigure(filepath)
fig = figure('Visible', 'off', 'Color', 'w');
cleanup = onCleanup(@() delete(fig));
layout = tiledlayout(fig, 2, 2);
for k = 1:4
    ax = nexttile(layout);
    plot(ax, 1:3, k + [0 1 0]);
    title(ax, "Panel " + char('A' + k - 1));
    xlabel(ax, "x-" + char('A' + k - 1));
    ylabel(ax, "y-" + char('A' + k - 1));
end
savefig(fig, filepath);
end

function drawGroupedBoxPlot(ax)
values = [1.1 1.4 1.7 2.2 2.8 3.1 5.6 6.1 6.7 7.2 7.8 8.4].';
groups = [ones(6, 1); 2 * ones(6, 1)];
boxplot(ax, values, groups, 'Labels', {'Baseline', 'Treatment'});
hold(ax, 'on');
xline(ax, 1.5, '--', 'Reference', 'HandleVisibility', 'off');
text(ax, 1.5, 8.7, 'Native group probe', 'HorizontalAlignment', 'center');
hold(ax, 'off');
title(ax, 'Grouped boxplot');
xlabel(ax, 'Cohort');
ylabel(ax, 'Synthetic score');
end

function assertNativeBoxPlot(testCase, preview, expectedLineCount, message)
testCase.verifyNotEmpty(preview);
testCase.verifyGreaterThanOrEqual( ...
    numel(findall(preview, 'Type', 'line')), expectedLineCount, message);
testCase.verifyTrue(any(string({findall(preview, 'Type', 'text').String}) == ...
    "Native group probe"), message);
end

function tf = hasNativeGroup(ax)
childClasses = string(arrayfun(@class, allchild(ax), ...
    "UniformOutput", false));
tf = any(childClasses == "matlab.graphics.primitive.Group");
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
