classdef FigureStudioResultFilesTest < matlab.unittest.TestCase
    %FIGURESTUDIORESULTFILESTEST Verify Figure Studio result-file exports.

    methods (Test, TestTags = {'Unit'})
        function axesPackageRecreatesCommonGraphics(testCase)
            setupLabKitTestPath();
            verify_axesPackageRecreatesCommonGraphics();
        end

        function figImportKeepsCompositeAppGraphics(testCase)
            setupLabKitTestPath();
            verify_figImportKeepsCompositeAppGraphics(testCase);
        end

        function presetStylesSemanticElementsByCategory(testCase)
            setupLabKitTestPath();
            verify_presetStylesSemanticElements(testCase);
        end

        function labkitPresetMatchesStandardFigureHierarchy(testCase)
            setupLabKitTestPath();
            style = figure_studio.styleLibrary.styleForPreset( ...
                "LabKit figure");

            testCase.verifyEqual( ...
                [style.canvasWidth style.canvasHeight style.exportScale], ...
                [1600 1333 2]);
            testCase.verifyEqual( ...
                [style.titleFontSize style.labelFontSize ...
                style.tickFontSize style.annotationFontSize ...
                style.legendFontSize], ...
                [60 72 60 54 64]);
            testCase.verifyEqual( ...
                [style.dataLineWidth style.uncertaintyLineWidth ...
                style.boundaryLineWidth style.referenceLineWidth ...
                style.axesLineWidth], ...
                [6.0 4.0 2.5 4.0 2.4]);
            testCase.verifyEqual(style.axesPosition, ...
                [0.185 0.17 0.795 0.78]);
            testCase.verifyTrue(style.boxVisible);
            testCase.verifyTrue(style.boundaryLines);
            testCase.verifyFalse(style.gridVisible);
            testCase.verifyEqual(style.legendBox, "On");
            testCase.verifyEqual(style.xTickLabelAngle, "Horizontal");
        end

        function semanticStyleScalesWithCanvasRelativeToReference(testCase)
            setupLabKitTestPath();
            cleanup = onCleanup(@() closeAllTestFigures());
            fig = figure('Visible', 'off');
            ax = axes('Parent', fig);
            curve = plot(ax, 1:3, [2 4 3]);
            title(ax, 'Scale probe');

            style = figure_studio.styleLibrary.styleForPreset( ...
                "LabKit figure");
            style.canvasWidth = 3200;
            style.canvasHeight = 2666;
            figure_studio.resultFiles.applyFigureStyle(ax, style);

            testCase.verifyEqual(fig.Position(3:4), [3200 2666]);
            testCase.verifyEqual(ax.FontSize, 120);
            testCase.verifyEqual(ax.Title.FontSize, 120);
            testCase.verifyEqual(ax.LineWidth, 4.8, 'AbsTol', 1e-12);
            testCase.verifyEqual(curve.LineWidth, 12, 'AbsTol', 1e-12);

            style.canvasWidth = 800;
            style.canvasHeight = 666.5;
            figure_studio.resultFiles.applyFigureStyle(ax, style);
            testCase.verifyEqual(fig.Position(3:4), [800 666.5]);
            testCase.verifyEqual(ax.FontSize, 30);
            testCase.verifyEqual(ax.Title.FontSize, 30);
            testCase.verifyEqual(ax.LineWidth, 1.2, 'AbsTol', 1e-12);
            testCase.verifyEqual(curve.LineWidth, 3, 'AbsTol', 1e-12);
            clear cleanup
        end
    end
end

function verify_presetStylesSemanticElements(testCase)
    cleanup = onCleanup(@() closeAllTestFigures());
    sourceFig = figure('Visible', 'off', 'Color', 'w');
    ax = axes('Parent', sourceFig);
    ax.Position = [0.18 0.24 0.68 0.56];
    hold(ax, 'on');
    curve = plot(ax, 1:3, [2 4 3], 'LineWidth', 4, ...
        'DisplayName', 'curve');
    uncertainty = errorbar(ax, 1:3, [2 4 3], 0.2 * ones(1, 3), ...
        'LineWidth', 4, 'DisplayName', 'uncertainty');
    bars = bar(ax, 1:3, [1 2 1.5], 'LineWidth', 4);
    region = rectangle(ax, 'Position', [1.2 1.5 1.5 2], ...
        'LineWidth', 4);
    reference = xline(ax, 2, 'LineWidth', 4);
    bracket = plot(ax, [1 1 3 3], [4.2 4.5 4.5 4.2], ...
        'k', 'LineWidth', 0.75, 'HandleVisibility', 'off');
    note = text(ax, 2, 4.8, 'manual annotation', ...
        'FontName', 'Courier', 'FontSize', 19);
    title(ax, 'Title');
    xlabel(ax, 'X name');
    ylabel(ax, 'Y name');
    lgd = legend(ax, 'show', 'FontSize', 18, 'Location', 'northwest');
    hold(ax, 'off');

    style = figure_studio.styleLibrary.styleForPreset("LabKit figure");
    style.xTickLabelAngle = "45 deg";
    figure_studio.resultFiles.applyFigureStyle(ax, style);
    testCase.verifyEqual(ax.FontSize, style.tickFontSize);
    testCase.verifyEqual(ax.Title.FontSize, style.titleFontSize);
    testCase.verifyEqual(ax.XLabel.FontSize, style.labelFontSize);
    testCase.verifyEqual(curve.LineWidth, style.dataLineWidth);
    testCase.verifyEqual( ...
        uncertainty.LineWidth, style.uncertaintyLineWidth);
    testCase.verifyEqual(bars.LineWidth, style.boundaryLineWidth);
    testCase.verifyEqual(region.LineWidth, style.boundaryLineWidth);
    testCase.verifyEqual(reference.LineWidth, style.referenceLineWidth);
    testCase.verifyEqual(bracket.LineWidth, 0.75, ...
        "Hidden annotation lines must retain their source width.");
    testCase.verifyEqual(string(note.FontName), string(style.fontName));
    testCase.verifyEqual(note.FontSize, style.annotationFontSize);
    testCase.verifyEqual(lgd.FontSize, style.legendFontSize);
    testCase.verifyEqual(lgd.Location, 'northwest');
    testCase.verifyEqual(string(lgd.Box), "on");
    testCase.verifyEqual(ax.XTickLabelRotation, 45);

    figure_studio.resultFiles.applyFigureStyle(ax, style);
    testCase.verifyEqual(note.FontSize, style.annotationFontSize, ...
        "Applying a preset twice must be idempotent.");
    clear cleanup
end

function verify_figImportKeepsCompositeAppGraphics(testCase)
    cleanup = onCleanup(@() closeAllTestFigures());
    sourceFig = figure('Visible', 'off', 'Color', 'w');
    ax = axes('Parent', sourceFig);
    hold(ax, 'on');
    bar(ax, 1:3, [2 4 3], 'DisplayName', 'Mean');
    errorbar(ax, 1:3, [2 4 3], [0.2 0.3 0.1], ...
        'DisplayName', 'Uncertainty');
    rectangle(ax, 'Position', [1.2 1.5 1.5 2]);
    xline(ax, 2, '-', 'Scientific threshold');
    text(ax, 2, 4.8, 'annotation');
    hold(ax, 'off');
    sourceLegend = legend(ax, 'show', 'Location', 'northwest', ...
        'Orientation', 'horizontal', 'Box', 'on', 'FontSize', 13);
    expectedLegendStrings = string(sourceLegend.String);

    filepath = string(tempname) + ".fig";
    fileCleanup = onCleanup(@() deleteIfFile(filepath));
    savefig(sourceFig, filepath);
    [plotData, style, resource] = figure_studio.sourceAxes.readFigFile(filepath);
    resourceCleanup = onCleanup(@() ...
        figure_studio.sourceAxes.closeResource(resource));
    [rebuiltFig, rebuiltAx] = ...
        figure_studio.resultFiles.createStyledFigure( ...
        plotData, style, resource.axes);

    expected = ["bar", "errorbar", "rectangle", "constantline", "text"];
    actual = string(get(findall(rebuiltAx, '-property', 'Type'), 'Type'));
    testCase.verifyTrue(all(ismember(expected, actual)), ...
        "FIG import should not drop common composite App graphics.");
    rebuiltLegend = rebuiltAx.Legend;
    testCase.verifyNotEmpty(rebuiltLegend, ...
        "FIG import should retain an existing legend.");
    testCase.verifyEqual(string(rebuiltLegend.String), ...
        expectedLegendStrings);
    testCase.verifyEqual(rebuiltLegend.Location, 'northwest');
    testCase.verifyEqual(rebuiltLegend.Orientation, 'horizontal');
    testCase.verifyEqual(rebuiltAx.Position, ax.Position, 'AbsTol', 1e-12, ...
        "FIG default export must retain the source axes placement.");
    testCase.verifyTrue(isvalid(rebuiltFig));
    clear resourceCleanup fileCleanup cleanup
end

function verify_axesPackageRecreatesCommonGraphics()
% Verify graphics data and reconstruction script export.

    cleanup = onCleanup(@() closeAllTestFigures());
    sourceFig = figure('Visible', 'off', 'Color', 'w');
    ax = axes('Parent', sourceFig);
    imagesc(ax, reshape(1:12, 3, 4));
    hold(ax, 'on');
    patch(ax, [1 3 3 1], [1 1 2 2], [0.2 0.8 0.4], ...
        'FaceAlpha', 0.35, 'EdgeColor', 'none', 'DisplayName', 'mask');
    bar(ax, 1:3, [1.2 1.8 1.4], 0.5, ...
        'FaceColor', [0.4 0.7 0.9], 'DisplayName', 'bars');
    errorbar(ax, 1:3, [2.2 2.5 2.1], [0.1 0.2 0.15], ...
        'Color', [0.2 0.2 0.2], 'CapSize', 8, ...
        'DisplayName', 'uncertainty');
    plot(ax, [1.4 1.4 2.6 2.6], [2.8 3.0 3.0 2.8], ...
        'Color', 'k', 'HandleVisibility', 'off');
    area(ax, 1:3, [0.3 0.4 0.2], ...
        'FaceAlpha', 0.2, 'DisplayName', 'area');
    rectangle(ax, 'Position', [1.25 0.75 1.5 1.5], ...
        'EdgeColor', 'm', 'LineStyle', '--');
    text(ax, 2, 2.5, 'A', 'FontName', 'Arial', 'FontSize', 14);
    xline(ax, 2, '--', 'Long scientific threshold', ...
        'Color', 'r', 'LineStyle', '--', ...
        'Alpha', 0.7);
    hold(ax, 'off');
    title(ax, 'Export Probe', 'Interpreter', 'none');
    xlabel(ax, 'X');
    ylabel(ax, 'Y');
    legend(ax, 'show', 'Location', 'southoutside', ...
        'Orientation', 'horizontal', 'Box', 'on', 'FontSize', 12);
    ax.YDir = 'reverse';
    ax.XGrid = 'on';
    ax.YGrid = 'on';
    ax.GridAlpha = 0.2;
    ax.Box = 'on';
    ax.XTick = 1:3;
    ax.XTickLabel = {'ST', 'PT', 'MT'};
    ax.XTickLabelRotation = 18;
    ax.TickLabelInterpreter = 'none';
    ax.DataAspectRatio = [1 1 1];
    ax.DataAspectRatioMode = 'manual';
    colormap(ax, gray(16));

    exportFolder = string(tempname);
    manifest = figure_studio.resultFiles.exportAxesPackage(ax, exportFolder);
    assert(isfile(manifest.mat) && isfile(manifest.script), ...
        'Axes export should write the authoritative MAT data and script.');

    data = load(manifest.mat, 'plotData');
    types = [data.plotData.objects.type];
    expectedTypes = [ ...
        "image", "patch", "bar", "errorbar", "area", "line", ...
        "rectangle", "text", "constantline"];
    assert(all(ismember(expectedTypes, types)), ...
        "Axes export should preserve every common App graphics object.");
    assert(string(data.plotData.axes.yDir) == "reverse" && ...
        string(data.plotData.axes.dataAspectRatioMode) == "manual", ...
        'Axes export should preserve axes direction and aspect metadata.');
    assert(isequal(string(data.plotData.axes.xTickLabel), ...
        ["ST"; "PT"; "MT"]) && ...
        data.plotData.axes.xTickLabelRotation == 18, ...
        'Axes export should preserve visible tick labels and rotation.');
    assert(data.plotData.axes.legend.enabled && ...
        string(data.plotData.axes.legend.location) == "southoutside" && ...
        string(data.plotData.axes.legend.orientation) == "horizontal", ...
        'Axes export should preserve existing legend metadata.');
    hiddenLine = data.plotData.objects(types == "line");
    assert(numel(hiddenLine) == 1 && ...
        string(hiddenLine.metadata.handleVisibility) == "off", ...
        'Visible hidden-handle annotations should remain out of legends.');
    assert(sum(types == "text") == 1, ...
        'Axes title and labels should not be duplicated as annotations.');

    run(char(manifest.script));
    assert(isvalid(fig), 'Reconstruction script should create a MATLAB figure.');
    rebuiltAxes = findobj(fig, 'Type', 'axes');
    assert(numel(rebuiltAxes) >= 1, ...
        'Reconstruction script should create an axes.');
    rebuiltAx = rebuiltAxes(1);
    assert(~isempty(findobj(rebuiltAx, 'Type', 'image')) && ...
        ~isempty(findobj(rebuiltAx, 'Type', 'patch')) && ...
        ~isempty(findobj(rebuiltAx, 'Type', 'bar')) && ...
        ~isempty(findobj(rebuiltAx, 'Type', 'errorbar')) && ...
        ~isempty(findobj(rebuiltAx, 'Type', 'area')) && ...
        ~isempty(allchildOfType(rebuiltAx, 'line')) && ...
        ~isempty(findobj(rebuiltAx, 'Type', 'rectangle')) && ...
        ~isempty(findobj(rebuiltAx, 'Type', 'text')) && ...
        ~isempty(findobj(rebuiltAx, 'Type', 'constantline')), ...
        'Reconstruction script should rebuild supported graphics objects.');
    threshold = findobj(rebuiltAx, 'Type', 'constantline');
    assert(any(string({threshold.Label}) == "Long scientific threshold"), ...
        "Constant-line labels should be restored as labels, not line specs.");
    rebuiltLegend = rebuiltAx.Legend;
    assert(~isempty(rebuiltLegend) && isvalid(rebuiltLegend) && ...
        strcmp(rebuiltLegend.Location, 'southoutside') && ...
        strcmp(rebuiltLegend.Orientation, 'horizontal') && ...
        strcmp(rebuiltLegend.Box, 'on'), ...
        'Reconstruction script should restore existing legend styling.');
    assert(strcmp(rebuiltAx.YDir, 'reverse') && ...
        strcmp(rebuiltAx.DataAspectRatioMode, 'manual') && ...
        strcmp(rebuiltAx.XGrid, 'on') && strcmp(rebuiltAx.Box, 'on'), ...
        'Reconstruction script should restore key axes display metadata.');
    assert(isequal(string(rebuiltAx.XTickLabel), ["ST"; "PT"; "MT"]) && ...
        rebuiltAx.XTickLabelRotation == 18, ...
        'Reconstruction script should restore custom tick labels.');
    rebuiltLines = allchildOfType(rebuiltAx, 'line');
    assert(any(string({rebuiltLines.HandleVisibility}) == "off"), ...
        'Reconstruction should retain hidden-handle annotation behavior.');
end

function closeAllTestFigures()
    delete(findall(groot, 'Type', 'figure'));
end

function deleteIfFile(filepath)
    if isfile(filepath)
        delete(filepath);
    end
end

function handles = allchildOfType(parent, type)
    handles = allchild(parent);
    handles = handles(arrayfun(@(handle) ...
        isgraphics(handle, type), handles));
end
