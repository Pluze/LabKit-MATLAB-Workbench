% Expected caller: the registered Figure Studio V2 renderer and export helper.
% Inputs are target axes plus a serializable plot/style model. Side effects
% are limited to drawing and styling the target axes.
function renderStudioPlot(ax, model)
    if isempty(model.plotData)
        labkit.ui.plot.clear(ax, "ResetScale", true);
        if isappdata(ax, 'labkitFigureStudioPlotData')
            rmappdata(ax, 'labkitFigureStudioPlotData');
        end
        if isappdata(ax, 'labkitFigureStudioPreviewStyle')
            rmappdata(ax, 'labkitFigureStudioPreviewStyle');
        end
        ax.Visible = 'off';
        title(ax, "No figure loaded");
        return;
    end
    samePlot = isappdata(ax, 'labkitFigureStudioPlotData') && ...
        isequaln(getappdata(ax, 'labkitFigureStudioPlotData'), model.plotData);
    if samePlot
        style = model.style;
        style.previewScale = logical(model.preview);
        figure_studio.resultFiles.applyFigureStyle(ax, style);
        if model.preview
            setappdata(ax, 'labkitFigureStudioPreviewStyle', style);
        end
        return;
    end
    labkit.ui.plot.clear(ax, "ResetScale", true);
    ax.Visible = 'on';
    disableDefaultAxesToolbar(ax);
    applyAxesMetadata(ax, model.plotData.axes);
    hold(ax, 'on');
    for k = 1:numel(model.plotData.objects)
        renderObject(ax, model.plotData.objects(k));
    end
    hold(ax, 'off');
    applyAxesMetadata(ax, model.plotData.axes);
    if any(strlength(string({model.plotData.objects.displayName})) > 0)
        legend(ax, 'show', 'Interpreter', 'none');
    end
    style = model.style;
    style.previewScale = logical(model.preview);
    figure_studio.resultFiles.applyFigureStyle(ax, style);
    if model.preview
        setappdata(ax, 'labkitFigureStudioPlotData', model.plotData);
        setappdata(ax, 'labkitFigureStudioPreviewStyle', style);
        labkit.ui.interaction.enablePopout(ax);
    end
end

function renderObject(ax, object)
    switch string(object.type)
        case "line"
            h = plot(ax, object.x, object.y, ...
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
        otherwise
            return;
    end
    applyStyle(h, object.style);
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
        h = yline(ax, value, char(label), ...
            'DisplayName', char(object.displayName));
    else
        h = xline(ax, value, char(label), ...
            'DisplayName', char(object.displayName));
    end
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
    title(ax, meta.title, 'Interpreter', 'none');
    xlabel(ax, meta.xLabel, 'Interpreter', 'none');
    ylabel(ax, meta.yLabel, 'Interpreter', 'none');
    zlabel(ax, meta.zLabel, 'Interpreter', 'none');
    mapping = { ...
        'XScale', 'xScale'; 'YScale', 'yScale'; 'ZScale', 'zScale'; ...
        'XDir', 'xDir'; 'YDir', 'yDir'; 'ZDir', 'zDir'; ...
        'XLim', 'xLim'; 'YLim', 'yLim'; 'ZLim', 'zLim'; ...
        'CLim', 'cLim'; 'Color', 'color'; 'Box', 'box'; ...
        'Layer', 'layer'; 'TickDir', 'tickDir'; ...
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
