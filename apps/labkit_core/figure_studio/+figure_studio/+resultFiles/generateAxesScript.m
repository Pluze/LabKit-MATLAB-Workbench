% Expected caller: figure_studio.resultFiles.writeAxesDataExport. Inputs are
% an export folder and plotData struct. Side effect: writes a standalone
% MATLAB script that recreates supported visible graphics objects from
% plot_data.mat.
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
    fprintf(fid, 'scriptFolder = fileparts(mfilename("fullpath"));\n');
    fprintf(fid, 'if strlength(string(scriptFolder)) == 0\n');
    fprintf(fid, '    scriptFolder = pwd;\n');
    fprintf(fid, 'end\n');
    fprintf(fid, 'data = load(fullfile(scriptFolder, "plot_data.mat"), "plotData");\n');
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
    fprintf(fid, '            applyObjectCoordinates(h, object);\n');
    fprintf(fid, '            applyStyle(h, object.style);\n');
    fprintf(fid, '        case "scatter"\n');
    fprintf(fid, '            h = scatter(ax, object.x, object.y, "DisplayName", char(object.displayName));\n');
    fprintf(fid, '            applyObjectCoordinates(h, object);\n');
    fprintf(fid, '            applyStyle(h, object.style);\n');
    fprintf(fid, '        case "image"\n');
    fprintf(fid, '            h = image(ax, "CData", object.c);\n');
    fprintf(fid, '            applyObjectCoordinates(h, object);\n');
    fprintf(fid, '            applyStyle(h, object.style);\n');
    fprintf(fid, '        case "surface"\n');
    fprintf(fid, '            h = surface(ax, object.x, object.y, object.z, object.c, "DisplayName", char(object.displayName));\n');
    fprintf(fid, '            applyObjectCoordinates(h, object);\n');
    fprintf(fid, '            applyStyle(h, object.style);\n');
    fprintf(fid, '        case "patch"\n');
    fprintf(fid, '            h = patch(ax, "XData", object.x, "YData", object.y, "DisplayName", char(object.displayName));\n');
    fprintf(fid, '            applyObjectCoordinates(h, object);\n');
    fprintf(fid, '            applyStyle(h, object.style);\n');
    fprintf(fid, '        case "text"\n');
    fprintf(fid, '            textValue = "";\n');
    fprintf(fid, '            if isfield(object.metadata, "text")\n');
    fprintf(fid, '                textValue = object.metadata.text;\n');
    fprintf(fid, '            end\n');
    fprintf(fid, '            h = text(ax, object.x(1), object.x(2), char(textValue), "DisplayName", char(object.displayName));\n');
    fprintf(fid, '            if numel(object.x) >= 3\n');
    fprintf(fid, '                h.Position = object.x;\n');
    fprintf(fid, '            end\n');
    fprintf(fid, '            applyStyle(h, object.style);\n');
    fprintf(fid, '        case "constantline"\n');
    fprintf(fid, '            h = createConstantLine(ax, object);\n');
    fprintf(fid, '            applyStyle(h, object.style);\n');
    fprintf(fid, '        otherwise\n');
    fprintf(fid, '            warning("LabKit:UnsupportedObject", "Skipped unsupported object type %%s.", object.type);\n');
    fprintf(fid, '    end\n');
    fprintf(fid, 'end\n');
    fprintf(fid, 'hold(ax, "off");\n');
    fprintf(fid, 'applyAxesMetadata(ax, plotData.axes);\n');
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
    fprintf(fid, 'safeSetIfField(ax, meta, "XDir", "xDir");\n');
    fprintf(fid, 'safeSetIfField(ax, meta, "YDir", "yDir");\n');
    fprintf(fid, 'safeSetIfField(ax, meta, "ZDir", "zDir");\n');
    fprintf(fid, 'safeSet(ax, "XLim", meta.xLim);\n');
    fprintf(fid, 'safeSet(ax, "YLim", meta.yLim);\n');
    fprintf(fid, 'if numel(meta.zLim) == 2\n');
    fprintf(fid, '    safeSet(ax, "ZLim", meta.zLim);\n');
    fprintf(fid, 'end\n');
    fprintf(fid, 'safeSet(ax, "CLim", meta.cLim);\n');
    fprintf(fid, 'safeSet(ax, "Layer", meta.view);\n');
    fprintf(fid, 'safeSet(ax, "Color", meta.color);\n');
    fprintf(fid, 'safeSetIfField(ax, meta, "Box", "box");\n');
    fprintf(fid, 'safeSetIfField(ax, meta, "Layer", "layer");\n');
    fprintf(fid, 'safeSetIfField(ax, meta, "TickDir", "tickDir");\n');
    fprintf(fid, 'safeSetIfField(ax, meta, "XGrid", "xGrid");\n');
    fprintf(fid, 'safeSetIfField(ax, meta, "YGrid", "yGrid");\n');
    fprintf(fid, 'safeSetIfField(ax, meta, "ZGrid", "zGrid");\n');
    fprintf(fid, 'safeSetIfField(ax, meta, "XMinorGrid", "xMinorGrid");\n');
    fprintf(fid, 'safeSetIfField(ax, meta, "YMinorGrid", "yMinorGrid");\n');
    fprintf(fid, 'safeSetIfField(ax, meta, "ZMinorGrid", "zMinorGrid");\n');
    fprintf(fid, 'safeSetIfField(ax, meta, "GridAlpha", "gridAlpha");\n');
    fprintf(fid, 'safeSetIfField(ax, meta, "MinorGridAlpha", "minorGridAlpha");\n');
    fprintf(fid, 'safeSetIfField(ax, meta, "DataAspectRatio", "dataAspectRatio");\n');
    fprintf(fid, 'safeSetIfField(ax, meta, "DataAspectRatioMode", "dataAspectRatioMode");\n');
    fprintf(fid, 'safeSetIfField(ax, meta, "PlotBoxAspectRatio", "plotBoxAspectRatio");\n');
    fprintf(fid, 'safeSetIfField(ax, meta, "PlotBoxAspectRatioMode", "plotBoxAspectRatioMode");\n');
    fprintf(fid, 'safeSetIfField(ax, meta, "ColorOrder", "colorOrder");\n');
    fprintf(fid, 'safeSet(ax, "FontName", meta.fontName);\n');
    fprintf(fid, 'safeSet(ax, "FontSize", meta.fontSize);\n');
    fprintf(fid, 'safeSet(ax, "LineWidth", meta.lineWidth);\n');
    fprintf(fid, 'if isfield(meta, "colormap") && ~isempty(meta.colormap)\n');
    fprintf(fid, '    colormap(ax, meta.colormap);\n');
    fprintf(fid, 'end\n');
    fprintf(fid, 'end\n');

    fprintf(fid, '\nfunction applyObjectCoordinates(h, object)\n');
    fprintf(fid, 'if ~isempty(object.x)\n');
    fprintf(fid, '    safeSet(h, "XData", object.x);\n');
    fprintf(fid, 'end\n');
    fprintf(fid, 'if ~isempty(object.y)\n');
    fprintf(fid, '    safeSet(h, "YData", object.y);\n');
    fprintf(fid, 'end\n');
    fprintf(fid, 'if ~isempty(object.z)\n');
    fprintf(fid, '    safeSet(h, "ZData", object.z);\n');
    fprintf(fid, 'end\n');
    fprintf(fid, 'if ~isempty(object.c)\n');
    fprintf(fid, '    safeSet(h, "CData", object.c);\n');
    fprintf(fid, 'end\n');
    fprintf(fid, 'if ~isempty(object.alpha)\n');
    fprintf(fid, '    safeSet(h, "AlphaData", object.alpha);\n');
    fprintf(fid, 'end\n');
    fprintf(fid, 'end\n');

    fprintf(fid, '\nfunction applyStyle(h, style)\n');
    fprintf(fid, 'fields = fieldnames(style);\n');
    fprintf(fid, 'for i = 1:numel(fields)\n');
    fprintf(fid, '    safeSet(h, fields{i}, style.(fields{i}));\n');
    fprintf(fid, 'end\n');
    fprintf(fid, 'end\n');

    fprintf(fid, '\nfunction h = createConstantLine(ax, object)\n');
    fprintf(fid, 'value = 0;\n');
    fprintf(fid, 'if isfield(object.metadata, "value") && ~isempty(object.metadata.value)\n');
    fprintf(fid, '    value = object.metadata.value;\n');
    fprintf(fid, 'end\n');
    fprintf(fid, 'label = "";\n');
    fprintf(fid, 'if isfield(object.metadata, "label")\n');
    fprintf(fid, '    label = object.metadata.label;\n');
    fprintf(fid, 'end\n');
    fprintf(fid, 'axisName = "x";\n');
    fprintf(fid, 'if isfield(object.metadata, "interceptAxis") && strlength(string(object.metadata.interceptAxis)) > 0\n');
    fprintf(fid, '    axisName = lower(string(object.metadata.interceptAxis));\n');
    fprintf(fid, 'end\n');
    fprintf(fid, 'if axisName == "y"\n');
    fprintf(fid, '    h = yline(ax, value, char(label), "DisplayName", char(object.displayName));\n');
    fprintf(fid, 'else\n');
    fprintf(fid, '    h = xline(ax, value, char(label), "DisplayName", char(object.displayName));\n');
    fprintf(fid, 'end\n');
    fprintf(fid, 'end\n');

    fprintf(fid, '\nfunction safeSetIfField(h, meta, propertyName, fieldName)\n');
    fprintf(fid, 'if isfield(meta, fieldName)\n');
    fprintf(fid, '    safeSet(h, propertyName, meta.(fieldName));\n');
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
