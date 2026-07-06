% Expected caller: Figure Studio result-file export. Input is one copied axes.
% Output is a plain struct snapshot of visible graphics objects and axes style
% metadata. It captures visible graphics, not app workflow state or
% recalculation-grade scientific exports.
function plotData = extractAxesData(ax)
    if isempty(ax) || ~isvalid(ax)
        error('labkit:ui:InvalidAxes', 'Axes handle is not valid.');
    end
    plotData = struct();
    plotData.schema = "figure_studio.resultFiles.axesData.v1";
    plotData.createdAt = datetime("now", "TimeZone", "local");
    plotData.axes = axesMetadata(ax);
    plotData.objects = emptyObject();
    plotData.warnings = strings(0, 1);

    children = flipud(ax.Children(:));
    for k = 1:numel(children)
        [object, warningText] = graphicsObjectData(children(k), ax);
        if strlength(warningText) > 0
            plotData.warnings(end + 1, 1) = warningText;
        end
        if isSupportedObject(object)
            plotData.objects(end + 1, 1) = object;
        end
    end
end

function meta = axesMetadata(ax)
    meta = struct();
    meta.title = labelText(ax.Title);
    meta.xLabel = labelText(ax.XLabel);
    meta.yLabel = labelText(ax.YLabel);
    meta.zLabel = labelText(ax.ZLabel);
    meta.xScale = string(ax.XScale);
    meta.yScale = string(ax.YScale);
    meta.zScale = string(ax.ZScale);
    meta.xDir = string(ax.XDir);
    meta.yDir = string(ax.YDir);
    meta.zDir = string(ax.ZDir);
    meta.xLim = ax.XLim;
    meta.yLim = ax.YLim;
    meta.zLim = ax.ZLim;
    meta.cLim = ax.CLim;
    meta.view = ax.View;
    meta.color = ax.Color;
    meta.box = string(ax.Box);
    meta.layer = string(ax.Layer);
    meta.tickDir = string(ax.TickDir);
    meta.xGrid = string(ax.XGrid);
    meta.yGrid = string(ax.YGrid);
    meta.zGrid = string(ax.ZGrid);
    meta.xMinorGrid = string(ax.XMinorGrid);
    meta.yMinorGrid = string(ax.YMinorGrid);
    meta.zMinorGrid = string(ax.ZMinorGrid);
    meta.gridAlpha = ax.GridAlpha;
    meta.minorGridAlpha = ax.MinorGridAlpha;
    meta.dataAspectRatio = ax.DataAspectRatio;
    meta.dataAspectRatioMode = string(ax.DataAspectRatioMode);
    meta.plotBoxAspectRatio = ax.PlotBoxAspectRatio;
    meta.plotBoxAspectRatioMode = string(ax.PlotBoxAspectRatioMode);
    meta.colorOrder = ax.ColorOrder;
    meta.fontName = string(ax.FontName);
    meta.fontSize = ax.FontSize;
    meta.lineWidth = ax.LineWidth;
    try
        meta.colormap = colormap(ax);
    catch
        meta.colormap = [];
    end
end

function object = emptyObject()
    object = objectTemplate();
    object(:) = [];
end

function object = objectTemplate()
    object = struct( ...
        'type', "", ...
        'displayName', "", ...
        'x', [], ...
        'y', [], ...
        'z', [], ...
        'c', [], ...
        'alpha', [], ...
        'style', struct(), ...
        'metadata', struct());
end

function [object, warningText] = graphicsObjectData(handle, ax)
    object = [];
    warningText = "";
    if isempty(handle) || ~isvalid(handle) || strcmp(handle.Visible, 'off')
        return;
    end
    if isgraphics(handle, 'line')
        object = lineData(handle);
    elseif isgraphics(handle, 'scatter')
        object = scatterData(handle);
    elseif isgraphics(handle, 'image')
        object = imageData(handle, ax);
    elseif isgraphics(handle, 'surface')
        object = surfaceData(handle);
    elseif isgraphics(handle, 'patch')
        object = patchData(handle);
    elseif isgraphics(handle, 'text')
        object = textData(handle);
    elseif isgraphics(handle, 'constantline')
        object = constantLineData(handle);
    else
        warningText = "Skipped unsupported graphics object: " + ...
            string(class(handle));
    end
end

function object = lineData(handle)
    object = baseObject("line", handle);
    object.x = columnData(handle.XData);
    object.y = columnData(handle.YData);
    object.z = optionalColumnData(handle, 'ZData');
    object.style = styleProps(handle, ...
        ["Color", "LineStyle", "Marker", "LineWidth", "MarkerSize"]);
end

function object = scatterData(handle)
    object = baseObject("scatter", handle);
    object.x = columnData(handle.XData);
    object.y = columnData(handle.YData);
    object.z = optionalColumnData(handle, 'ZData');
    object.c = optionalValue(handle, 'CData');
    object.style = styleProps(handle, ...
        ["Marker", "SizeData", "LineWidth", "MarkerFaceColor", ...
        "MarkerEdgeColor"]);
end

function object = imageData(handle, ax)
    object = baseObject("image", handle);
    object.x = optionalValue(handle, 'XData');
    object.y = optionalValue(handle, 'YData');
    object.c = handle.CData;
    object.alpha = optionalValue(handle, 'AlphaData');
    object.style = styleProps(handle, ["AlphaDataMapping", "CDataMapping", ...
        "Interpolation"]);
    object.metadata.colormap = colormap(ax);
    object.metadata.cLim = ax.CLim;
end

function object = surfaceData(handle)
    object = baseObject("surface", handle);
    object.x = optionalValue(handle, 'XData');
    object.y = optionalValue(handle, 'YData');
    object.z = optionalValue(handle, 'ZData');
    object.c = optionalValue(handle, 'CData');
    object.alpha = optionalValue(handle, 'AlphaData');
    object.style = styleProps(handle, ...
        ["FaceColor", "EdgeColor", "LineStyle", "LineWidth", ...
        "Marker", "MarkerSize", "FaceAlpha", "EdgeAlpha"]);
end

function object = patchData(handle)
    object = baseObject("patch", handle);
    object.x = optionalValue(handle, 'XData');
    object.y = optionalValue(handle, 'YData');
    object.z = optionalValue(handle, 'ZData');
    object.c = optionalValue(handle, 'CData');
    object.alpha = optionalValue(handle, 'AlphaData');
    object.style = styleProps(handle, ...
        ["FaceColor", "FaceAlpha", "EdgeColor", "EdgeAlpha", ...
        "LineStyle", "LineWidth", "Marker", "MarkerSize", ...
        "CDataMapping", "AlphaDataMapping"]);
end

function object = textData(handle)
    object = baseObject("text", handle);
    object.x = optionalValue(handle, 'Position');
    object.metadata.text = labelText(handle);
    object.style = styleProps(handle, ...
        ["Color", "FontName", "FontSize", "FontWeight", "FontAngle", ...
        "HorizontalAlignment", "VerticalAlignment", "Rotation", "Interpreter"]);
end

function object = constantLineData(handle)
    object = baseObject("constantline", handle);
    object.metadata.value = optionalValue(handle, 'Value');
    object.metadata.interceptAxis = string(optionalValue(handle, 'InterceptAxis'));
    object.metadata.label = string(optionalValue(handle, 'Label'));
    object.style = styleProps(handle, ...
        ["Color", "LineStyle", "LineWidth", "Alpha", ...
        "LabelHorizontalAlignment", "LabelVerticalAlignment", ...
        "FontName", "FontSize"]);
end

function object = baseObject(type, handle)
    object = objectTemplate();
    object.type = string(type);
    object.displayName = displayName(handle);
    object.metadata.class = string(class(handle));
end

function value = displayName(handle)
    value = "";
    if isprop(handle, 'DisplayName')
        try
            value = string(handle.DisplayName);
        catch
            value = "";
        end
    end
    if strlength(value) == 0 || startsWith(value, "_")
        value = "";
    end
end

function value = optionalColumnData(handle, prop)
    value = [];
    if isprop(handle, prop)
        value = columnData(handle.(prop));
    end
end

function value = optionalValue(handle, prop)
    value = [];
    if isprop(handle, prop)
        value = handle.(prop);
    end
end

function value = columnData(value)
    value = value(:);
end

function style = styleProps(handle, names)
    style = struct();
    for k = 1:numel(names)
        name = char(names(k));
        if isprop(handle, name)
            try
                style.(name) = handle.(name);
            catch
            end
        end
    end
end

function text = labelText(labelHandle)
    if isprop(labelHandle, 'String')
        value = labelHandle.String;
    else
        value = "";
    end
    if iscell(value)
        text = string(strjoin(value, newline));
    else
        text = string(value);
    end
end

function tf = isSupportedObject(object)
    tf = isstruct(object) && isfield(object, 'type') && ...
        isscalar(string(object.type)) && strlength(string(object.type)) > 0;
end
