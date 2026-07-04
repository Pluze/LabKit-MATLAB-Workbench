% Private UI tool helper. Expected caller: popout export services. Input is
% one copied axes. Output is a plain struct snapshot of visible graphics
% objects and axes style metadata. It intentionally captures visible graphics,
% not app workflow state or recalculation-grade scientific exports.
function plotData = extractAxesData(ax)
    if isempty(ax) || ~isvalid(ax)
        error('labkit:ui:InvalidAxes', 'Axes handle is not valid.');
    end
    plotData = struct();
    plotData.schema = "labkit.ui.tool.axesData.v1";
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
        if ~isempty(object)
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
    meta.xLim = ax.XLim;
    meta.yLim = ax.YLim;
    meta.zLim = ax.ZLim;
    meta.cLim = ax.CLim;
    meta.view = ax.View;
    meta.color = ax.Color;
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
    object = struct( ...
        'type', string.empty(0, 1), ...
        'displayName', string.empty(0, 1), ...
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
    object.style = styleProps(handle, ["AlphaDataMapping", "CDataMapping"]);
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
        "Marker", "MarkerSize"]);
end

function object = baseObject(type, handle)
    object = emptyObject();
    object.type = string(type);
    object.displayName = displayName(handle);
    object.metadata.class = string(class(handle));
end

function value = displayName(handle)
    value = "";
    if isprop(handle, 'DisplayName')
        value = string(handle.DisplayName);
    end
    if strlength(value) == 0 || startsWith(value, "_")
        value = string(class(handle));
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
    value = labelHandle.String;
    if iscell(value)
        text = string(strjoin(value, newline));
    else
        text = string(value);
    end
end
