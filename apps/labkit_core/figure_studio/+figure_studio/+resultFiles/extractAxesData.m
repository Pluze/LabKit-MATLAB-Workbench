% Expected caller: Figure Studio result-file export. Input is one copied axes.
% Output is a plain struct snapshot of visible graphics objects and axes style
% metadata. It captures visible graphics, not app workflow state or
% recalculation-grade scientific exports.
function plotData = extractAxesData(ax)
    if isempty(ax) || ~isvalid(ax)
        error('figure_studio:resultFiles:InvalidAxes', ...
            'Axes handle is not valid.');
    end
    plotData = struct();
    plotData.schema = "figure_studio.resultFiles.axesData.v1";
    plotData.createdAt = datetime("now", "TimeZone", "local");
    plotData.axes = axesMetadata(ax);
    plotData.objects = emptyObject();
    plotData.warnings = strings(0, 1);

    children = visiblePlotChildren(ax);
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

function children = visiblePlotChildren(ax)
    children = flipud(allchild(ax));
    children = children(:);
    labelProperties = ["Title", "Subtitle", "XLabel", "YLabel", "ZLabel"];
    for property = labelProperties
        if ~isprop(ax, property)
            continue;
        end
        label = ax.(property);
        children(children == label) = [];
    end
    children = expandVisibleGroups(children);
end

function children = expandVisibleGroups(children)
    expanded = gobjects(0, 1);
    for k = 1:numel(children)
        child = children(k);
        if isgraphics(child, 'hggroup')
            if isprop(child, 'Visible') && string(child.Visible) == "off"
                continue;
            end
            expanded = [expanded; expandVisibleGroups(flipud(allchild(child)))];
        else
            expanded(end + 1, 1) = child;
        end
    end
    children = expanded;
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
    meta.xTick = ax.XTick;
    meta.yTick = ax.YTick;
    meta.zTick = ax.ZTick;
    meta.xExponent = rulerExponent(ax, 'XAxis');
    meta.yExponent = rulerExponent(ax, 'YAxis');
    meta.zExponent = rulerExponent(ax, 'ZAxis');
    meta.xTickLabel = ax.XTickLabel;
    meta.yTickLabel = ax.YTickLabel;
    meta.zTickLabel = ax.ZTickLabel;
    meta.xTickLabelRotation = ax.XTickLabelRotation;
    meta.yTickLabelRotation = ax.YTickLabelRotation;
    meta.zTickLabelRotation = ax.ZTickLabelRotation;
    meta.tickLabelInterpreter = string(ax.TickLabelInterpreter);
    meta.xAxisLocation = string(ax.XAxisLocation);
    meta.yAxisLocation = string(ax.YAxisLocation);
    meta.tickLength = ax.TickLength;
    meta.view = ax.Layer;
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
    meta.legend = legendMetadata(ax);
    try
        meta.colormap = colormap(ax);
    catch
        meta.colormap = [];
    end
end

function value = rulerExponent(ax, rulerName)
value = [];
try
    ruler = ax.(rulerName);
    if isprop(ruler, 'Exponent')
        value = ruler.Exponent;
    end
catch
end
end

function meta = legendMetadata(ax)
    meta = struct( ...
        "enabled", false, ...
        "visible", "off", ...
        "strings", strings(0, 1), ...
        "location", "best", ...
        "orientation", "vertical", ...
        "numColumns", 1, ...
        "fontName", string(ax.FontName), ...
        "fontSize", ax.FontSize, ...
        "box", "off", ...
        "interpreter", "none");
    if ~isprop(ax, 'Legend') || isempty(ax.Legend) || ~isvalid(ax.Legend)
        return;
    end
    owner = ax.Legend;
    meta.enabled = true;
    meta.visible = string(optionalValue(owner, 'Visible'));
    meta.strings = string(optionalValue(owner, 'String'));
    meta.location = string(optionalValue(owner, 'Location'));
    meta.orientation = string(optionalValue(owner, 'Orientation'));
    meta.numColumns = optionalValue(owner, 'NumColumns');
    meta.fontName = string(optionalValue(owner, 'FontName'));
    meta.fontSize = optionalValue(owner, 'FontSize');
    meta.box = string(optionalValue(owner, 'Box'));
    meta.interpreter = string(optionalValue(owner, 'Interpreter'));
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
    elseif isgraphics(handle, 'bar')
        object = barData(handle);
    elseif isgraphics(handle, 'errorbar')
        object = errorBarData(handle);
    elseif isgraphics(handle, 'area')
        object = areaData(handle);
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
    elseif isgraphics(handle, 'rectangle')
        object = rectangleData(handle);
    else
        warningText = "Skipped unsupported graphics object: " + ...
            string(class(handle));
    end
end

function object = barData(handle)
    object = baseObject("bar", handle);
    object.x = optionalValue(handle, 'XData');
    object.y = optionalValue(handle, 'YData');
    object.c = optionalValue(handle, 'CData');
    object.style = styleProps(handle, ...
        ["FaceColor", "FaceAlpha", "EdgeColor", "EdgeAlpha", ...
        "LineStyle", "LineWidth", "BarWidth", "BaseValue", ...
        "Horizontal", "CDataMapping"]);
end

function object = errorBarData(handle)
    object = baseObject("errorbar", handle);
    object.x = optionalValue(handle, 'XData');
    object.y = optionalValue(handle, 'YData');
    object.metadata.yNegativeDelta = optionalValue(handle, 'YNegativeDelta');
    object.metadata.yPositiveDelta = optionalValue(handle, 'YPositiveDelta');
    object.metadata.xNegativeDelta = optionalValue(handle, 'XNegativeDelta');
    object.metadata.xPositiveDelta = optionalValue(handle, 'XPositiveDelta');
    object.style = styleProps(handle, ...
        ["Color", "LineStyle", "LineWidth", "Marker", "MarkerSize", ...
        "MarkerEdgeColor", "MarkerFaceColor", "CapSize"]);
end

function object = areaData(handle)
    object = baseObject("area", handle);
    object.x = optionalValue(handle, 'XData');
    object.y = optionalValue(handle, 'YData');
    object.c = optionalValue(handle, 'CData');
    object.style = styleProps(handle, ...
        ["FaceColor", "FaceAlpha", "EdgeColor", "EdgeAlpha", ...
        "LineStyle", "LineWidth", "BaseValue", "CDataMapping"]);
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

function object = rectangleData(handle)
    object = baseObject("rectangle", handle);
    object.metadata.position = optionalValue(handle, 'Position');
    object.metadata.curvature = optionalValue(handle, 'Curvature');
    object.style = styleProps(handle, ...
        ["EdgeColor", "FaceColor", "LineStyle", "LineWidth"]);
end

function object = baseObject(type, handle)
    object = objectTemplate();
    object.type = string(type);
    object.displayName = displayName(handle);
    object.metadata.class = string(class(handle));
    object.metadata.handleVisibility = string(optionalValue( ...
        handle, 'HandleVisibility'));
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
