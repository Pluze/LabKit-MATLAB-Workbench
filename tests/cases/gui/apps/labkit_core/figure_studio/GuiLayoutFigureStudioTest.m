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
            testCase.verifyEqual(style.baseFontSize, 45);
            testCase.verifyEqual(style.titleFontSize, 45);
            testCase.verifyEqual(style.labelFontSize, 45);
            testCase.verifyEqual(style.tickFontSize, 45);
            testCase.verifyEqual(style.annotationFontSize, 45);
            testCase.verifyEqual(style.legendFontSize, 45);
            testCase.verifyEqual(style.legendTokenWidth, 100);
            testCase.verifyEqual(style.dataLineWidth, 6);
            testCase.verifyEqual(style.uncertaintyLineWidth, 2);
            testCase.verifyEqual(style.boundaryLineWidth, 1.5);
            testCase.verifyEqual(style.referenceLineWidth, 1.5);
            testCase.verifyEqual(style.axesLineWidth, 1.5);
            testCase.verifyEmpty(style.axesPosition);
            testCase.verifyEqual([style.canvasWidth style.canvasHeight], ...
                [900 725]);
            testCase.verifyEqual( ...
                [style.referenceCanvasWidth style.referenceCanvasHeight], ...
                [900 725]);
            testCase.verifyEqual( ...
                runtime.State.project.parameters.aspectPreset, "Reference");
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
            testCase.verifyEmpty(findall(ax, "Type", "image"), ...
                "The workbench preview must remain an interactive axes.");
            testCase.verifyNotEmpty(findall(ax, "Type", "line"));
            testCase.verifyEqual(string( ...
                findall(fig, "Tag", "exportCurrent").Enable), "on");
            testCase.verifyFalse(contains( ...
                join(string(ax.Title.String), " "), " | file "));
            originalLimits = runtime.State.session.cache.plotData.axes.xLim;
            originalRevision = runtime.State.session.cache.viewRevision;
            runtime.invokeAction("recalculateLimits");
            testCase.verifyNotEqual( ...
                runtime.State.session.cache.plotData.axes.xLim, originalLimits, ...
                "The explicit limit action should recover the visible data extent.");
            testCase.verifyGreaterThan( ...
                runtime.State.session.cache.viewRevision, originalRevision);
            testCase.verifyEqual(ax.XLim, ...
                runtime.State.session.cache.plotData.axes.xLim, ...
                "Recalculation must replace the current interactive viewport.");
            limitState = runtime.State.session.cache.limitState;
            testCase.verifyGreaterThanOrEqual(limitState.xMin, limitState.xRange(1));
            testCase.verifyLessThanOrEqual(limitState.xMax, limitState.xRange(2));
            manualXMin = mean([limitState.xMin limitState.xMax]);
            runtime.applyControlValue("xMin", manualXMin);
            testCase.verifyEqual(ax.XLim(1), manualXMin);

            canvasBeforePreset = [style.canvasWidth style.canvasHeight];
            axesFrameBeforePreset = style.axesPosition;
            runtime.applyControlValue("stylePreset", "FIG default");
            testCase.verifyEqual( ...
                [runtime.State.project.parameters.style.canvasWidth ...
                runtime.State.project.parameters.style.canvasHeight], ...
                canvasBeforePreset, ...
                "Text-style presets must not change canvas dimensions.");
            testCase.verifyEqual( ...
                runtime.State.project.parameters.style.axesPosition, ...
                axesFrameBeforePreset, ...
                "Text-style presets must not change the canvas frame.");
            runtime.applyControlValue("stylePreset", "LabKit figure");
            runtime.applyControlValue("boundaryLines", "Off");
            testCase.verifyEqual(string(ax.Box), "off");

            runtime.invokeAction("exportPng");
            testCase.verifyTrue(isfile(pngPath));
            pngInfo = imfinfo(pngPath);
            testCase.verifyGreaterThan(double(pngInfo.Width), 1200, ...
                "Export must include the configured plot frame and its outer text margins.");
            testCase.verifyGreaterThan(double(pngInfo.Height), 675, ...
                "Export must include the configured plot frame and its outer text margins.");
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
                initialProject.parameters.style.tickFontSize, 45);
            testCase.verifyEqual( ...
                initialProject.parameters.style.axesLineWidth, 1.5);
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
            testCase.verifyEqual( ...
                runtime.State.session.cache.currentSource, "Popout axes");
            testCase.verifyEmpty(findall(ax, "Type", "image"));
            testCase.verifyEqual(string(ax.Title.String), "Probe");
            testCase.verifyEqual(string( ...
                findall(fig, "Tag", "exportCurrent").Enable), "on");
            style = runtime.State.project.parameters.style;
            canvasRatio = double(style.canvasWidth) / ...
                double(style.canvasHeight);
            testCase.verifyEqual(canvasRatio, 900 / 725, 'AbsTol', 0.02);
            testCase.verifyEqual( ...
                runtime.State.project.parameters.aspectPreset, "Reference");

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

        function figure_studio_renders_an_interactive_export_proportioned_preview(testCase)
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

            testCase.verifyEmpty(findall(ax, "Type", "image"));
            previewLine = findall(ax, "Type", "line");
            testCase.verifyNumElements(previewLine, 1);
            testCase.verifyEqual(string(ax.Title.String), "");
            testCase.verifyEqual(ax.PlotBoxAspectRatio(1) / ...
                ax.PlotBoxAspectRatio(2), 900 / 725, 'AbsTol', 0.04);
            ax.XLim = [4 8];
            fig.Position(3:4) = [760 540];
            drawnow;
            testCase.verifyEqual(ax.XLim, [4 8], ...
                "Workspace resize must preserve the interactive viewport.");
            testCase.verifyEqual(previewLine.XData, linspace(0, 30, 200));
            fontBefore = ax.FontSize;
            lineBefore = previewLine.LineWidth;
            fig.Position(3:4) = [420 320];
            drawnow;
            figure_studio.sourceAxes.refreshPreviewScale(ax);
            previewPixels = getpixelposition(ax, true);
            expectedScale = min(previewPixels(3) / 900, ...
                previewPixels(4) / 725);
            expectedScale = min(1, max(0.15, expectedScale));
            testCase.verifyLessThanOrEqual(ax.FontSize, fontBefore);
            testCase.verifyLessThanOrEqual(previewLine.LineWidth, lineBefore);
            testCase.verifyEqual(ax.FontSize, 45 * expectedScale, ...
                'RelTol', 1e-6, ...
                "Preview text must follow the actual allocated plot area.");
            testCase.verifyEqual(previewLine.LineWidth, 6 * expectedScale, ...
                'RelTol', 1e-6, ...
                "Preview strokes must follow the actual allocated plot area.");
        end

        function popout_send_to_studio_copies_plot_content(testCase)
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
            testCase.verifyEmpty(findall(preview, "Type", "image"));
            testCase.verifyEqual(string(preview.Title.String), "Source Plot");
            clear hookCleanup cleanup;
        end

        function uiAxesExportPreservesScientificAxisExponent(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            sourceFigure = uifigure('Visible', 'off');
            sourceAxes = uiaxes(sourceFigure);
            plot(sourceAxes, [0 2e5 4e5], [0 1e4 2e4], '-o');
            sourceAxes.XAxis.Exponent = 5;
            sourceAxes.XAxis.ExponentMode = 'manual';
            sourceAxes.YAxis.Exponent = 4;
            sourceAxes.YAxis.ExponentMode = 'manual';
            plotData = figure_studio.resultFiles.extractAxesData(sourceAxes);
            style = figure_studio.styleLibrary.styleForPreset( ...
                "LabKit figure");
            [exportFigure, exportAxes] = ...
                figure_studio.resultFiles.createStyledFigure( ...
                plotData, style, sourceAxes);
            exportCleanup = onCleanup(@() delete(exportFigure));

            testCase.verifyNotEmpty(findall(exportAxes, 'Type', 'line'));
            testCase.verifyEqual(double(exportAxes.XAxis.Exponent), 5);
            testCase.verifyEqual(double(exportAxes.YAxis.Exponent), 4);
            clear exportCleanup cleanup;
        end
    end
end

function assertFigureStudioLayout(h, fig)
h.assertStartupSucceeded(fig);
ids = ["figFiles", "currentSource", "sourcePanel", "statusSummary", "recalculateLimits", ...
    "xMin", "xMax", "yMin", "yMax", "stylePreset", ...
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
summaries = [1.1 1.4 1.7 2.2 2.8 3.1; ...
    5.6 6.1 6.7 7.2 7.8 8.4];
hold(ax, 'on');
for groupIndex = 1:size(summaries, 1)
    drawNativeBoxGroup(ax, groupIndex, summaries(groupIndex, :));
end
xline(ax, 1.5, '--', 'Reference', 'HandleVisibility', 'off');
text(ax, 1.5, 8.7, 'Native group probe', 'HorizontalAlignment', 'center');
hold(ax, 'off');
ax.XLim = [0.5 2.5];
ax.XTick = [1 2];
ax.XTickLabel = {'Baseline', 'Treatment'};
title(ax, 'Grouped boxplot');
xlabel(ax, 'Cohort');
ylabel(ax, 'Synthetic score');
end

function drawNativeBoxGroup(ax, x, values)
group = hggroup('Parent', ax, 'Tag', sprintf('boxplot-group-%d', x));
width = 0.25;
low = values(1);
lowerQuartile = values(2);
medianValue = values(3);
upperQuartile = values(4);
high = values(5);
outlier = values(6);
common = {'Color', [0 0.4470 0.7410], 'LineWidth', 1.5};
line('Parent', group, 'XData', ...
    [x-width x+width x+width x-width x-width], 'YData', ...
    [lowerQuartile lowerQuartile upperQuartile upperQuartile lowerQuartile], ...
    common{:}, 'Tag', 'Box');
line('Parent', group, 'XData', [x-width x+width], ...
    'YData', [medianValue medianValue], common{:}, 'Tag', 'Median');
line('Parent', group, 'XData', [x x], ...
    'YData', [low lowerQuartile], common{:}, 'Tag', 'Lower Whisker');
line('Parent', group, 'XData', [x x], ...
    'YData', [upperQuartile high], common{:}, 'Tag', 'Upper Whisker');
line('Parent', group, 'XData', [x-width/2 x+width/2], ...
    'YData', [low low], common{:}, 'Tag', 'Lower Adjacent Value');
line('Parent', group, 'XData', [x-width/2 x+width/2], ...
    'YData', [high high], common{:}, 'Tag', 'Upper Adjacent Value');
line('Parent', group, 'XData', x, 'YData', outlier, ...
    common{:}, 'LineStyle', 'none', 'Marker', '+', 'Tag', 'Outliers');
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
