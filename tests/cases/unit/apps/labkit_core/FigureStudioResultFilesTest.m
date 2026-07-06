classdef FigureStudioResultFilesTest < matlab.unittest.TestCase
    %FIGURESTUDIORESULTFILESTEST Verify Figure Studio result-file exports.

    methods (Test, TestTags = {'Unit'})
        function axesPackageRecreatesCommonGraphics(testCase)
            setupLabKitTestPath();
            verify_axesPackageRecreatesCommonGraphics();
        end
    end
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
    text(ax, 2, 2.5, 'A', 'FontName', 'Arial', 'FontSize', 14);
    xline(ax, 2, 'R', 'Color', 'r', 'LineStyle', '--', ...
        'Alpha', 0.7);
    hold(ax, 'off');
    title(ax, 'Export Probe', 'Interpreter', 'none');
    xlabel(ax, 'X');
    ylabel(ax, 'Y');
    ax.YDir = 'reverse';
    ax.XGrid = 'on';
    ax.YGrid = 'on';
    ax.GridAlpha = 0.2;
    ax.Box = 'on';
    ax.DataAspectRatio = [1 1 1];
    ax.DataAspectRatioMode = 'manual';
    colormap(ax, gray(16));

    exportFolder = string(tempname);
    manifest = figure_studio.resultFiles.exportAxesPackage(ax, exportFolder);
    assert(isfile(manifest.mat) && isfile(manifest.script), ...
        'Axes export should write the authoritative MAT data and script.');

    data = load(manifest.mat, 'plotData');
    types = [data.plotData.objects.type];
    assert(any(types == "image") && any(types == "patch") && ...
        any(types == "text") && any(types == "constantline"), ...
        ['Axes export should preserve common image, patch, text, and ' ...
        'constant-line objects.']);
    assert(string(data.plotData.axes.yDir) == "reverse" && ...
        string(data.plotData.axes.dataAspectRatioMode) == "manual", ...
        'Axes export should preserve axes direction and aspect metadata.');

    run(char(manifest.script));
    assert(isvalid(fig), 'Reconstruction script should create a MATLAB figure.');
    rebuiltAxes = findobj(fig, 'Type', 'axes');
    assert(numel(rebuiltAxes) >= 1, ...
        'Reconstruction script should create an axes.');
    rebuiltAx = rebuiltAxes(1);
    assert(~isempty(findobj(rebuiltAx, 'Type', 'image')) && ...
        ~isempty(findobj(rebuiltAx, 'Type', 'patch')) && ...
        ~isempty(findobj(rebuiltAx, 'Type', 'text')) && ...
        ~isempty(findobj(rebuiltAx, 'Type', 'constantline')), ...
        'Reconstruction script should rebuild supported graphics objects.');
    assert(strcmp(rebuiltAx.YDir, 'reverse') && ...
        strcmp(rebuiltAx.DataAspectRatioMode, 'manual') && ...
        strcmp(rebuiltAx.XGrid, 'on') && strcmp(rebuiltAx.Box, 'on'), ...
        'Reconstruction script should restore key axes display metadata.');
end

function closeAllTestFigures()
    delete(findall(groot, 'Type', 'figure'));
end
