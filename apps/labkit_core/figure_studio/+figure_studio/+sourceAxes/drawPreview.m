% Expected caller: the registered Figure Studio App SDK renderer and export
% helper.
% Inputs are target axes plus a serializable plot/style model. Side effects
% are limited to drawing and styling the target axes.
function drawPreview(axesById, model)
    ax = axesById.main;
    if isempty(model.plotData)
        labkit.app.plot.clearAxes(ax);
        if isappdata(ax, 'labkitFigureStudioPlotData')
            rmappdata(ax, 'labkitFigureStudioPlotData');
        end
        if isappdata(ax, 'labkitFigureStudioPreviewStyle')
            rmappdata(ax, 'labkitFigureStudioPreviewStyle');
        end
        if isappdata(ax, 'labkitFigureStudioExportPreview')
            rmappdata(ax, 'labkitFigureStudioExportPreview');
        end
        ax.Visible = 'off';
        title(ax, "No figure loaded");
        return;
    end
    if hasNativeSource(model)
        figure_studio.sourceAxes.copyToPreview(model.sourceAxes, ax);
        if isappdata(ax, 'labkitFigureStudioExportPreview')
            rmappdata(ax, 'labkitFigureStudioExportPreview');
        end
        figure_studio.sourceAxes.applyAxesPresentation( ...
            ax, model.plotData.axes);
        style = model.style;
        style.previewScale = logical(model.preview);
        figure_studio.resultFiles.applyFigureStyle(ax, style);
        configureInteractivePreview(ax, style);
        return;
    end
    labkit.app.plot.clearAxes(ax);
    ax.Visible = 'on';
    disableDefaultAxesToolbar(ax);
    applyAxesMetadata(ax, model.plotData.axes);
    hold(ax, 'on');
    for k = 1:numel(model.plotData.objects)
        renderObject(ax, model.plotData.objects(k));
    end
    hold(ax, 'off');
    applyAxesMetadata(ax, model.plotData.axes);
    applyLegendMetadata(ax, model.plotData);
    style = model.style;
    style.previewScale = logical(model.preview);
    figure_studio.resultFiles.applyFigureStyle(ax, style);
    if model.preview
        setappdata(ax, 'labkitFigureStudioPlotData', model.plotData);
        setappdata(ax, 'labkitFigureStudioPreviewStyle', style);
        configureInteractivePreview(ax, style);
        figure_studio.sourceAxes.resizePreview(ax, style);
    end
end

function configureInteractivePreview(ax, style)
if ~logical(style.previewScale)
    return;
end
setappdata(ax, 'labkitFigureStudioPreviewStyle', style);
setappdata(ax, 'labkitFigureStudioPreviewSize', previewPixelSize(ax));
if ~isappdata(ax, 'labkitFigureStudioPreviewResizeInstalled')
    try
        ax.SizeChangedFcn = @(src, ~) ...
            figure_studio.sourceAxes.refreshPreviewScale(src);
        setappdata(ax, 'labkitFigureStudioPreviewResizeInstalled', true);
    catch
    end
end
end

function size = previewPixelSize(ax)
size = [0 0];
try
    position = getpixelposition(ax, true);
    size = round(position(3:4));
catch
end
end

function tf = hasNativeSource(model)
tf = isstruct(model) && isfield(model, "sourceAxes") && ...
    ~isempty(model.sourceAxes) && ...
    isscalar(model.sourceAxes) && isgraphics(model.sourceAxes, "axes");
end

function applyLegendMetadata(ax, plotData)
    hasNames = any(strlength(string({plotData.objects.displayName})) > 0);
    if isfield(plotData.axes, 'legend')
        meta = plotData.axes.legend;
        if ~logical(fieldValue(meta, 'enabled', false))
            return;
        end
    elseif hasNames
        meta = struct();
    else
        return;
    end
    lgd = legend(ax, 'show', 'Interpreter', 'none');
    mapping = { ...
        'String', 'strings'; ...
        'Location', 'location'; ...
        'Orientation', 'orientation'; ...
        'NumColumns', 'numColumns'; ...
        'FontName', 'fontName'; ...
        'FontSize', 'fontSize'; ...
        'Box', 'box'; ...
        'Interpreter', 'interpreter'; ...
        'Visible', 'visible'};
    for k = 1:size(mapping, 1)
        if isfield(meta, mapping{k, 2})
            safeSet(lgd, mapping{k, 1}, meta.(mapping{k, 2}));
        end
    end
end

function renderObject(ax, object)
    switch string(object.type)
        case "line"
            h = plot(ax, object.x, object.y, ...
                'DisplayName', char(object.displayName));
            applyCoordinates(h, object);
        case "bar"
            h = bar(ax, object.x, object.y, ...
                'DisplayName', char(object.displayName));
            applyCoordinates(h, object);
        case "errorbar"
            h = renderErrorBar(ax, object);
        case "area"
            h = area(ax, object.x, object.y, ...
                'DisplayName', char(object.displayName));
            applyCoordinates(h, object);
        case "scatter"
            h = scatter(ax, object.x, object.y, ...
                'DisplayName', char(object.displayName));
            applyCoordinates(h, object);
        case "image"
            h = image(ax, 'CData', object.c);
            applyCoordinates(h, object);
        case "surface"
            h = surface(ax, object.x, object.y, object.z, object.c, ...
                'DisplayName', char(object.displayName));
            applyCoordinates(h, object);
        case "patch"
            h = patch(ax, 'XData', object.x, 'YData', object.y, ...
                'DisplayName', char(object.displayName));
            applyCoordinates(h, object);
        case "text"
            h = renderText(ax, object);
        case "constantline"
            h = renderConstantLine(ax, object);
        case "rectangle"
            h = renderRectangle(ax, object);
        otherwise
            return;
    end
    applyStyle(h, object.style);
    safeSet(h, 'HandleVisibility', ...
        fieldValue(object.metadata, 'handleVisibility', 'on'));
end

function h = renderErrorBar(ax, object)
    yNegative = fieldValue(object.metadata, 'yNegativeDelta', []);
    yPositive = fieldValue(object.metadata, 'yPositiveDelta', []);
    xNegative = fieldValue(object.metadata, 'xNegativeDelta', []);
    xPositive = fieldValue(object.metadata, 'xPositiveDelta', []);
    if ~isempty(xNegative) || ~isempty(xPositive)
        h = errorbar(ax, object.x, object.y, ...
            yNegative, yPositive, xNegative, xPositive, ...
            'DisplayName', char(object.displayName));
    else
        h = errorbar(ax, object.x, object.y, ...
            yNegative, yPositive, ...
            'DisplayName', char(object.displayName));
    end
end

function h = renderText(ax, object)
    value = "";
    if isfield(object.metadata, 'text')
        value = string(object.metadata.text);
    end
    position = double(object.x(:).');
    if numel(position) < 2
        position = [0 0 0];
    end
    h = text(ax, position(1), position(2), char(value), ...
        'DisplayName', char(object.displayName));
    if numel(position) >= 3
        h.Position = position(1:3);
    end
end

function h = renderConstantLine(ax, object)
    value = fieldValue(object.metadata, 'value', 0);
    label = string(fieldValue(object.metadata, 'label', ""));
    interceptAxis = lower(string(fieldValue( ...
        object.metadata, 'interceptAxis', "x")));
    if interceptAxis == "y"
        h = yline(ax, value, ...
            'DisplayName', char(object.displayName));
    else
        h = xline(ax, value, ...
            'DisplayName', char(object.displayName));
    end
    h.Label = char(label);
end

function h = renderRectangle(ax, object)
    position = fieldValue(object.metadata, 'position', [0 0 1 1]);
    curvature = fieldValue(object.metadata, 'curvature', [0 0]);
    h = rectangle(ax, ...
        'Position', position, ...
        'Curvature', curvature, ...
        'HitTest', 'off', ...
        'PickableParts', 'none');
end

function applyCoordinates(h, object)
    values = {object.x, object.y, object.z, object.c, object.alpha};
    names = {'XData', 'YData', 'ZData', 'CData', 'AlphaData'};
    for k = 1:numel(names)
        if ~isempty(values{k})
            safeSet(h, names{k}, values{k});
        end
    end
end

function applyStyle(h, style)
    names = fieldnames(style);
    for k = 1:numel(names)
        safeSet(h, names{k}, style.(names{k}));
    end
end

function applyAxesMetadata(ax, meta)
    title(ax, meta.title, 'Interpreter', ...
        labelInterpreter(meta, 'titleInterpreter'));
    xlabel(ax, meta.xLabel, 'Interpreter', ...
        labelInterpreter(meta, 'xLabelInterpreter'));
    ylabel(ax, meta.yLabel, 'Interpreter', ...
        labelInterpreter(meta, 'yLabelInterpreter'));
    zlabel(ax, meta.zLabel, 'Interpreter', ...
        labelInterpreter(meta, 'zLabelInterpreter'));
    mapping = { ...
        'XScale', 'xScale'; 'YScale', 'yScale'; 'ZScale', 'zScale'; ...
        'XDir', 'xDir'; 'YDir', 'yDir'; 'ZDir', 'zDir'; ...
        'XLim', 'xLim'; 'YLim', 'yLim'; 'ZLim', 'zLim'; ...
        'XTick', 'xTick'; 'YTick', 'yTick'; 'ZTick', 'zTick'; ...
        'XTickLabel', 'xTickLabel'; 'YTickLabel', 'yTickLabel'; ...
        'ZTickLabel', 'zTickLabel'; ...
        'XTickLabelRotation', 'xTickLabelRotation'; ...
        'YTickLabelRotation', 'yTickLabelRotation'; ...
        'ZTickLabelRotation', 'zTickLabelRotation'; ...
        'TickLabelInterpreter', 'tickLabelInterpreter'; ...
        'XAxisLocation', 'xAxisLocation'; ...
        'YAxisLocation', 'yAxisLocation'; 'TickLength', 'tickLength'; ...
        'CLim', 'cLim'; 'Color', 'color'; 'Box', 'box'; ...
        'Layer', 'layer'; 'TickDir', 'tickDir'; ...
        'XMinorTick', 'xMinorTick'; 'YMinorTick', 'yMinorTick'; ...
        'ZMinorTick', 'zMinorTick'; ...
        'XGrid', 'xGrid'; 'YGrid', 'yGrid'; 'ZGrid', 'zGrid'; ...
        'XMinorGrid', 'xMinorGrid'; 'YMinorGrid', 'yMinorGrid'; ...
        'ZMinorGrid', 'zMinorGrid'; 'GridAlpha', 'gridAlpha'; ...
        'MinorGridAlpha', 'minorGridAlpha'; ...
        'DataAspectRatio', 'dataAspectRatio'; ...
        'DataAspectRatioMode', 'dataAspectRatioMode'; ...
        'PlotBoxAspectRatio', 'plotBoxAspectRatio'; ...
        'PlotBoxAspectRatioMode', 'plotBoxAspectRatioMode'; ...
        'ColorOrder', 'colorOrder'; 'FontName', 'fontName'; ...
        'FontSize', 'fontSize'; 'LineWidth', 'lineWidth'};
    for k = 1:size(mapping, 1)
        if isfield(meta, mapping{k, 2})
            safeSet(ax, mapping{k, 1}, meta.(mapping{k, 2}));
        end
    end
    if isfield(meta, 'colormap') && ~isempty(meta.colormap)
        colormap(ax, meta.colormap);
    end
    if applyRulerExponent(ax, 'XAxis', fieldValue(meta, 'xExponent', []))
        safeSet(ax, 'XTickLabelMode', 'auto');
    end
    if applyRulerExponent(ax, 'YAxis', fieldValue(meta, 'yExponent', []))
        safeSet(ax, 'YTickLabelMode', 'auto');
    end
    if applyRulerExponent(ax, 'ZAxis', fieldValue(meta, 'zExponent', []))
        safeSet(ax, 'ZTickLabelMode', 'auto');
    end
end

function value = labelInterpreter(meta, name)
value = string(fieldValue(meta, name, "none"));
if ~isscalar(value) || ~any(value == ["tex", "latex", "none"])
    value = "none";
end
end

function applied = applyRulerExponent(ax, rulerName, value)
applied = false;
if isempty(value) || ~isscalar(value) || ~isfinite(value)
    return;
end
try
    ruler = ax.(rulerName);
    if isprop(ruler, 'Exponent')
        ruler.Exponent = value;
        if isprop(ruler, 'ExponentMode')
            ruler.ExponentMode = 'manual';
        end
        applied = value ~= 0;
    end
catch
end
end

function value = fieldValue(owner, name, fallback)
    value = fallback;
    if isstruct(owner) && isfield(owner, name) && ~isempty(owner.(name))
        value = owner.(name);
    end
end

function safeSet(h, name, value)
    try
        if isprop(h, name)
            h.(name) = value;
        end
    catch
    end
end

function disableDefaultAxesToolbar(ax)
    try
        ax.Toolbar.Visible = 'off';
        disableDefaultInteractivity(ax);
    catch
    end
end
