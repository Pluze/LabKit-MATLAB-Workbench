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
            hint = semanticHint(children(k), ax);
            if strlength(hint) > 0
                object.metadata.semanticHint = hint;
            end
            [side, confidence] = inferYAxisSide(children(k), ax);
            if isappdata(children(k), 'figureStudioLegendPosition')
                position = getappdata(children(k), 'figureStudioLegendPosition');
                if isnumeric(position) && isscalar(position) && isfinite(position) && position >= 1
                    object.metadata.legendPosition = position;
                    % An explicitly edited name is user text, including a leading underscore.
                    object.displayName = string(children(k).DisplayName);
                end
            end
            if isappdata(children(k), 'figureStudioLegendSourceName')
                object.metadata.sourceLegendName = string(getappdata(children(k), 'figureStudioLegendSourceName'));
            end
            object.metadata.yAxisSide = side;
            object.metadata.yAxisSideConfidence = confidence;
            plotData.objects(end + 1, 1) = object;
        end
    end
    positions = inf(numel(plotData.objects), 1);
    editedLegend = false;
    for k = 1:numel(plotData.objects)
        metadata = plotData.objects(k).metadata;
        if isfield(metadata, 'legendPosition')
            editedLegend = true;
            if metadata.handleVisibility ~= "off", positions(k) = metadata.legendPosition; end
        end
    end
    if editedLegend
        plotData.axes.legend.edited = true;
        [~, order] = sort(positions);
        order = order(isfinite(positions(order)));
        plotData.axes.legend.objectIndices = order(:).';
        plotData.axes.legend.strings = string({plotData.objects(order).displayName});
    end
end

function hint = semanticHint(handle, ax)
hint = "";
if isgraphics(handle, "line")
    x = optionalValue(handle, "XData");
    y = optionalValue(handle, "YData");
    if isBracket(x, y)
        hint = "significance-bracket";
    end
elseif isgraphics(handle, "patch")
    x = optionalValue(handle, "XData");
    y = optionalValue(handle, "YData");
    if isAxisWindow(x, y, ax)
        hint = "analysis-window";
    end
elseif isgraphics(handle, "scatter")
    tag = lower(string(optionalValue(handle, "Tag")));
    if contains(tag, "point") || contains(tag, "peak")
        hint = "measurement-point";
    end
end
end

function tf = isBracket(x, y)
x = double(x(:).');
y = double(y(:).');
tf = numel(x) == 4 && numel(y) == 4 && ...
    approximately(x(1), x(2)) && approximately(x(3), x(4)) && ...
    approximately(y(1), y(4)) && approximately(y(2), y(3)) && ...
    y(2) > y(1);
end

function tf = isAxisWindow(x, y, ax)
x = double(x(:));
y = double(y(:));
if numel(x) ~= 4 || numel(y) ~= 4 || numel(unique(x)) ~= 2
    tf = false;
    return;
end
limits = double(ax.YLim);
tolerance = max(diff(limits), 1) * 1e-8;
tf = abs(min(y) - limits(1)) <= tolerance && ...
    abs(max(y) - limits(2)) <= tolerance;
end

function tf = approximately(left, right)
tf = abs(left - right) <= max([abs(left), abs(right), 1]) * 1e-10;
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
    if isempty(children)
        children = gobjects(0, 1);
        return;
    end
    chunks = cell(numel(children), 1);
    for k = 1:numel(children)
        child = children(k);
        if isgraphics(child, 'hggroup')
            if isprop(child, 'Visible') && string(child.Visible) == "off"
                continue;
            end
            chunks{k} = expandVisibleGroups(flipud(allchild(child)));
        else
            chunks{k} = child;
        end
    end
    expanded = vertcat(chunks{:});
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
    meta.yAxes = yAxesMetadata(ax);
    if numel(meta.yAxes) > 1
        primary = meta.yAxes(1);
        meta.yLabel = primary.label;
        meta.yScale = primary.scale;
        meta.yDir = primary.direction;
        meta.yLim = primary.limits;
        meta.yTick = primary.tickValues;
        meta.yTickLabel = primary.tickLabels;
        meta.yExponent = primary.exponent;
    end
    meta.legend = legendMetadata(ax);
    meta.colorbar = colorbarMetadata(ax);
    try
        meta.colormap = colormap(ax);
    catch
        meta.colormap = [];
    end
end

function meta = colorbarMetadata(ax)
meta = struct("enabled", false, "label", "", "location", "eastoutside", ...
    "limits", ax.CLim, "ticks", [], "tickLabels", strings(0, 1), ...
    "fontName", "", "fontSize", []);
try
    bar = ax.Colorbar;
    if isempty(bar) || ~isvalid(bar), return; end
    meta.enabled = string(bar.Visible) == "on";
    meta.label = labelText(bar.Label);
    meta.location = string(bar.Location);
    meta.limits = bar.Limits;
    meta.ticks = bar.Ticks;
    meta.tickLabels = string(bar.TickLabels);
    meta.fontName = string(bar.FontName);
    meta.fontSize = bar.FontSize;
catch
end
end

function values = yAxesMetadata(ax)
template = struct("side", "left", "scale", "linear", ...
    "direction", "normal", "limits", [0 1], "tickValues", [], ...
    "tickLabels", strings(0, 1), "exponent", [], "label", "", ...
    "color", []);
try
    rulers = ax.YAxis;
catch
    values = template([]);
    return;
end
values = repmat(template, numel(rulers), 1);
sides = ["left", "right"];
for k = 1:numel(rulers)
    ruler = rulers(k);
    value = template;
    value.side = sides(min(k, numel(sides)));
    value.scale = string(ruler.Scale);
    value.direction = string(ruler.Direction);
    value.limits = ruler.Limits;
    value.tickValues = ruler.TickValues;
    value.tickLabels = string(ruler.TickLabels);
    if isprop(ruler, "Exponent")
        value.exponent = ruler.Exponent;
    end
    value.label = labelText(ruler.Label);
    value.color = ruler.Color;
    values(k, 1) = value;
end
end

function [side, confidence] = inferYAxisSide(handle, ax)
side = "left";
confidence = "single-axis";
try
    rulers = ax.YAxis;
catch
    return;
end
if numel(rulers) < 2
    return;
end
values = optionalValue(handle, "YData");
scores = [rangeOverflow(values, rulers(1).Limits), ...
    rangeOverflow(values, rulers(2).Limits)];
if abs(scores(1) - scores(2)) > 1e-12
    [~, index] = min(scores);
    confidence = "range";
else
    objectColor = numericColor(optionalValue(handle, "Color"));
    distances = [colorDistance(objectColor, rulers(1).Color), ...
        colorDistance(objectColor, rulers(2).Color)];
    if all(isfinite(distances)) && abs(distances(1) - distances(2)) > 1e-12
        [~, index] = min(distances);
        confidence = "color";
    else
        index = 1;
        confidence = "fallback";
    end
end
sides = ["left", "right"];
side = sides(index);
end

function score = rangeOverflow(values, limits)
values = double(values(:));
values = values(isfinite(values));
limits = double(limits(:));
if isempty(values) || numel(limits) ~= 2 || diff(limits) <= 0
    score = inf;
    return;
end
span = diff(limits);
score = sum(max(limits(1) - values, 0) + max(values - limits(2), 0)) / ...
    (span * numel(values));
end

function value = numericColor(value)
if isnumeric(value) && numel(value) == 3 && all(isfinite(value))
    value = double(reshape(value, 1, 3));
else
    value = [];
end
end

function value = colorDistance(left, right)
left = numericColor(left);
right = numericColor(right);
if isempty(left) || isempty(right)
    value = inf;
else
    value = norm(left - right);
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
    elseif isBoxChart(handle)
        object = boxChartData(handle);
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

function tf = isBoxChart(handle)
    tf = contains(lower(string(class(handle))), "boxchart");
end

function object = boxChartData(handle)
    object = baseObject("boxchart", handle);
    object.x = optionalValue(handle, 'XData');
    object.y = optionalValue(handle, 'YData');
    object.style = styleProps(handle, ...
        ["BoxWidth", "BoxFaceColor", "BoxFaceAlpha", "BoxEdgeColor", ...
        "BoxMedianLineColor", "WhiskerLineColor", "WhiskerLineStyle", ...
        "MarkerStyle", "MarkerColor", "MarkerSize", "LineWidth", ...
        "ColorGroupLayout", "ColorGroupWidth"]);
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
    object.metadata.tag = string(optionalValue(handle, 'Tag'));
    parent = handle.Parent;
    if isgraphics(parent, "hggroup")
        object.metadata.sourceGroupTag = string(optionalValue(parent, "Tag"));
        object.metadata.sourceGroupName = displayName(parent);
    end
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
