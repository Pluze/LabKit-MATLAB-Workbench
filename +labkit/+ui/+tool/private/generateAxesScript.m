% Private UI tool helper. Expected caller: writeAxesDataExport. Inputs are an
% export folder and plotData struct. Side effect: writes a standalone MATLAB
% script that recreates supported visible graphics objects from plot_data.mat.
function scriptPath = generateAxesScript(folder, plotData)
    scriptPath = fullfile(string(folder), "recreate_plot.m");
    fid = fopen(scriptPath, 'w');
    if fid < 0
        error('labkit:ui:ExportWriteFailed', ...
            'Could not write recreate_plot.m.');
    end
    cleanup = onCleanup(@() fclose(fid));

    fprintf(fid, '%% Recreate a LabKit visible plot export.\n');
    fprintf(fid, '%% Generated %s.\n', char(string(plotData.createdAt)));
    fprintf(fid, 'data = load("plot_data.mat", "plotData");\n');
    fprintf(fid, 'plotData = data.plotData;\n');
    fprintf(fid, 'fig = figure("Color", "w", "Name", "LabKit Plot Export");\n');
    fprintf(fid, 'ax = axes("Parent", fig);\n');
    fprintf(fid, 'hold(ax, "on");\n');
    fprintf(fid, 'applyAxesMetadata(ax, plotData.axes);\n');
    fprintf(fid, 'for k = 1:numel(plotData.objects)\n');
    fprintf(fid, '    object = plotData.objects(k);\n');
    fprintf(fid, '    switch string(object.type)\n');
    fprintf(fid, '        case "line"\n');
    fprintf(fid, '            h = plot(ax, object.x, object.y, "DisplayName", char(object.displayName));\n');
    fprintf(fid, '            applyStyle(h, object.style);\n');
    fprintf(fid, '        case "scatter"\n');
    fprintf(fid, '            h = scatter(ax, object.x, object.y, "DisplayName", char(object.displayName));\n');
    fprintf(fid, '            applyStyle(h, object.style);\n');
    fprintf(fid, '        case "image"\n');
    fprintf(fid, '            h = image(ax, "CData", object.c);\n');
    fprintf(fid, '            applyImageCoordinates(h, object);\n');
    fprintf(fid, '            applyStyle(h, object.style);\n');
    fprintf(fid, '        case "surface"\n');
    fprintf(fid, '            h = surface(ax, object.x, object.y, object.z, object.c, "DisplayName", char(object.displayName));\n');
    fprintf(fid, '            applyStyle(h, object.style);\n');
    fprintf(fid, '        otherwise\n');
    fprintf(fid, '            warning("LabKit:UnsupportedObject", "Skipped unsupported object type %%s.", object.type);\n');
    fprintf(fid, '    end\n');
    fprintf(fid, 'end\n');
    fprintf(fid, 'hold(ax, "off");\n');
    fprintf(fid, 'if any(strlength(string({plotData.objects.displayName})) > 0)\n');
    fprintf(fid, '    legend(ax, "show", "Interpreter", "none");\n');
    fprintf(fid, 'end\n');
    writeLocalFunctions(fid);
end

function writeLocalFunctions(fid)
    fprintf(fid, '\nfunction applyAxesMetadata(ax, meta)\n');
    fprintf(fid, 'title(ax, meta.title, "Interpreter", "none");\n');
    fprintf(fid, 'xlabel(ax, meta.xLabel, "Interpreter", "none");\n');
    fprintf(fid, 'ylabel(ax, meta.yLabel, "Interpreter", "none");\n');
    fprintf(fid, 'zlabel(ax, meta.zLabel, "Interpreter", "none");\n');
    fprintf(fid, 'safeSet(ax, "XScale", meta.xScale);\n');
    fprintf(fid, 'safeSet(ax, "YScale", meta.yScale);\n');
    fprintf(fid, 'safeSet(ax, "ZScale", meta.zScale);\n');
    fprintf(fid, 'safeSet(ax, "XLim", meta.xLim);\n');
    fprintf(fid, 'safeSet(ax, "YLim", meta.yLim);\n');
    fprintf(fid, 'if numel(meta.zLim) == 2\n');
    fprintf(fid, '    safeSet(ax, "ZLim", meta.zLim);\n');
    fprintf(fid, 'end\n');
    fprintf(fid, 'safeSet(ax, "CLim", meta.cLim);\n');
    fprintf(fid, 'safeSet(ax, "View", meta.view);\n');
    fprintf(fid, 'safeSet(ax, "Color", meta.color);\n');
    fprintf(fid, 'safeSet(ax, "FontName", meta.fontName);\n');
    fprintf(fid, 'safeSet(ax, "FontSize", meta.fontSize);\n');
    fprintf(fid, 'safeSet(ax, "LineWidth", meta.lineWidth);\n');
    fprintf(fid, 'if isfield(meta, "colormap") && ~isempty(meta.colormap)\n');
    fprintf(fid, '    colormap(ax, meta.colormap);\n');
    fprintf(fid, 'end\n');
    fprintf(fid, 'end\n');

    fprintf(fid, '\nfunction applyImageCoordinates(h, object)\n');
    fprintf(fid, 'if ~isempty(object.x)\n');
    fprintf(fid, '    h.XData = object.x;\n');
    fprintf(fid, 'end\n');
    fprintf(fid, 'if ~isempty(object.y)\n');
    fprintf(fid, '    h.YData = object.y;\n');
    fprintf(fid, 'end\n');
    fprintf(fid, 'if ~isempty(object.alpha)\n');
    fprintf(fid, '    h.AlphaData = object.alpha;\n');
    fprintf(fid, 'end\n');
    fprintf(fid, 'end\n');

    fprintf(fid, '\nfunction applyStyle(h, style)\n');
    fprintf(fid, 'fields = fieldnames(style);\n');
    fprintf(fid, 'for i = 1:numel(fields)\n');
    fprintf(fid, '    safeSet(h, fields{i}, style.(fields{i}));\n');
    fprintf(fid, 'end\n');
    fprintf(fid, 'end\n');

    fprintf(fid, '\nfunction safeSet(h, name, value)\n');
    fprintf(fid, 'try\n');
    fprintf(fid, '    if isprop(h, name)\n');
    fprintf(fid, '        h.(char(name)) = value;\n');
    fprintf(fid, '    end\n');
    fprintf(fid, 'catch\n');
    fprintf(fid, 'end\n');
    fprintf(fid, 'end\n');
end
