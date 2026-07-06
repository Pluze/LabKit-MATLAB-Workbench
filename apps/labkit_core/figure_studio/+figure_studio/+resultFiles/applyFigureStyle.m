% Expected caller: Figure Studio preview, save, and quick-export actions.
% Inputs are a scalar axes handle and either a style name or Figure Studio
% style struct. Side effects are limited to the copied preview/export axes.
function applyFigureStyle(ax, preset)
%APPLYFIGURESTYLE Apply publication-style cleanup to one axes.
%
% Inputs:
%   ax - scalar MATLAB axes or UI axes handle.
%   preset - optional scalar text or struct. Supported text values are
%       "nature" and "labkit". Struct presets may provide fontName,
%       baseFontSize, titleFontOffset, labelFontOffset, tickFontOffset,
%       titleFontSize, labelFontSize, tickFontSize,
%       dataLineWidth, axesLineWidth, gridAlpha, gridVisible, boxVisible,
%       boundaryLines, canvasWidth, canvasHeight, previewScale, and
%       colorOrder fields.
%
% Output:
%   None. The copied graphics state is changed in place.
%
% Behavior:
%   Uses editable sans-serif text, hides the top/right box where MATLAB allows
%   it, strengthens axes/tick/data lines, removes legend boxes, and applies a
%   restrained semantic color order suitable for later SVG/PDF export.

    if nargin < 2
        preset = "nature";
    end
    if isempty(ax) || ~isvalid(ax)
        error('labkit:ui:InvalidAxes', 'Axes handle is not valid.');
    end
    if isstruct(preset)
        applyStyleStruct(ax, preset);
        return;
    end
    switch lower(string(preset))
        case {"nature", "labkit"}
            applyStyleStruct(ax, defaultNatureStyle());
        otherwise
            error('figure_studio:resultFiles:InvalidFigureStyle', ...
                'Unsupported figure style preset "%s".', string(preset));
    end
end

function applyStyleStruct(ax, style)
    style = fillStyle(style);
    viewScale = applyCanvasGeometry(ax, style);
    style = scaledStyle(style, viewScale);
    ax.FontName = char(style.fontName);
    ax.FontSize = style.tickFontSize;
    ax.LineWidth = style.axesLineWidth;
    ax.Box = onOff(style.boxVisible || style.boundaryLines);
    ax.TickDir = 'out';
    ax.ColorOrder = style.colorOrder;
    if style.gridVisible
        grid(ax, 'on');
        ax.GridAlpha = style.gridAlpha;
    else
        grid(ax, 'off');
    end
    styleLabels(ax);
    styleLabelsFromStyle(ax, style);
    styleDataChildren(ax, style);
    styleLegend(ax);
end

function style = defaultNatureStyle()
    style = struct( ...
        "fontName", preferredFont(), ...
        "baseFontSize", 12, ...
        "titleFontSize", 14, ...
        "labelFontSize", 12, ...
        "tickFontSize", 11, ...
        "dataLineWidth", 1.75, ...
        "axesLineWidth", 1.5, ...
        "gridAlpha", 0.12, ...
        "gridVisible", false, ...
        "boxVisible", false, ...
        "boundaryLines", false, ...
        "canvasWidth", 1200, ...
        "canvasHeight", 900, ...
        "previewScale", false, ...
        "colorOrder", natureColorOrder());
end

function style = fillStyle(style)
    defaults = defaultNatureStyle();
    names = fieldnames(defaults);
    for k = 1:numel(names)
        name = names{k};
        if ~isfield(style, name) || isempty(style.(name))
            style.(name) = defaults.(name);
        end
    end
    style.baseFontSize = finiteScalar(style.baseFontSize, defaults.baseFontSize);
    style.titleFontOffset = finiteScalar(optionalField(style, ...
        'titleFontOffset', 2), 2);
    style.labelFontOffset = finiteScalar(optionalField(style, ...
        'labelFontOffset', 0), 0);
    style.tickFontOffset = finiteScalar(optionalField(style, ...
        'tickFontOffset', -1), -1);
    style.titleFontSize = finiteScalar(style.titleFontSize, ...
        style.baseFontSize + style.titleFontOffset);
    style.labelFontSize = finiteScalar(style.labelFontSize, ...
        style.baseFontSize + style.labelFontOffset);
    style.tickFontSize = finiteScalar(style.tickFontSize, ...
        style.baseFontSize + style.tickFontOffset);
    style.dataLineWidth = finiteScalar(style.dataLineWidth, defaults.dataLineWidth);
    style.axesLineWidth = finiteScalar(style.axesLineWidth, defaults.axesLineWidth);
    style.gridAlpha = min(max(finiteScalar(style.gridAlpha, defaults.gridAlpha), 0), 1);
    style.gridVisible = logical(style.gridVisible);
    style.boxVisible = logical(style.boxVisible);
    style.boundaryLines = logical(style.boundaryLines);
    style.canvasWidth = finiteScalar(style.canvasWidth, defaults.canvasWidth);
    style.canvasHeight = finiteScalar(style.canvasHeight, defaults.canvasHeight);
    style.previewScale = logical(style.previewScale);
end

function style = scaledStyle(style, scale)
    style.titleFontSize = max(1, style.titleFontSize * scale);
    style.labelFontSize = max(1, style.labelFontSize * scale);
    style.tickFontSize = max(1, style.tickFontSize * scale);
    style.dataLineWidth = max(0.1, style.dataLineWidth * scale);
    style.axesLineWidth = max(0.1, style.axesLineWidth * scale);
end

function value = optionalField(style, name, fallback)
    if isfield(style, name) && ~isempty(style.(name))
        value = style.(name);
    else
        value = fallback;
    end
end

function value = finiteScalar(value, fallback)
    value = double(value);
    if ~isscalar(value) || ~isfinite(value)
        value = fallback;
    end
end

function name = preferredFont()
    names = listfonts;
    preferred = ["Arial", "Liberation Sans", "DejaVu Sans"];
    name = "Arial";
    for k = 1:numel(preferred)
        if any(strcmpi(names, preferred(k)))
            name = preferred(k);
            return;
        end
    end
end

function colors = natureColorOrder()
    colors = [ ...
        15 77 146
        182 67 66
        66 148 158
        118 118 118
        55 117 186
        139 207 139] ./ 255;
end

function styleLabels(ax)
    labels = {ax.Title, ax.XLabel, ax.YLabel, ax.ZLabel};
    for k = 1:numel(labels)
        label = labels{k};
        if isempty(label) || ~isvalid(label)
            continue;
        end
        label.FontName = ax.FontName;
        label.FontSize = ax.FontSize;
        label.FontWeight = 'normal';
    end
    ax.Title.FontWeight = 'bold';
end

function styleDataChildren(ax, style)
    children = findall(ax, '-property', 'LineWidth');
    for k = 1:numel(children)
        child = children(k);
        if isempty(child) || ~isvalid(child) || child == ax
            continue;
        end
        if isDataGraphic(child)
            child.LineWidth = style.dataLineWidth;
        end
    end
end

function styleLabelsFromStyle(ax, style)
    ax.FontSize = style.tickFontSize;
    ax.Title.FontSize = style.titleFontSize;
    ax.XLabel.FontSize = style.labelFontSize;
    ax.YLabel.FontSize = style.labelFontSize;
    ax.ZLabel.FontSize = style.labelFontSize;
end

function tf = isDataGraphic(handle)
    tf = isa(handle, 'matlab.graphics.chart.primitive.Line') || ...
        isa(handle, 'matlab.graphics.chart.primitive.Scatter') || ...
        isa(handle, 'matlab.graphics.chart.primitive.ErrorBar') || ...
        isa(handle, 'matlab.graphics.primitive.Patch') || ...
        isa(handle, 'matlab.graphics.primitive.Surface');
end

function value = onOff(tf)
    if tf
        value = 'on';
    else
        value = 'off';
    end
end

function styleLegend(ax)
    legends = findall(ancestor(ax, 'figure'), 'Type', 'legend');
    for k = 1:numel(legends)
        try
            legends(k).Box = 'off';
            legends(k).FontName = ax.FontName;
            legends(k).FontSize = ax.FontSize;
        catch
        end
    end
end

function scale = applyCanvasGeometry(ax, style)
    width = max(1, double(style.canvasWidth));
    height = max(1, double(style.canvasHeight));
    applyAxesCanvasFrame(ax, width, height);
    try
        pbaspect(ax, [width height 1]);
    catch
    end
    fig = ancestor(ax, 'figure');
    if isempty(fig) || ~isvalid(fig) || isa(fig, 'matlab.ui.Figure')
        scale = previewScale(ax, style, width, height);
        return;
    end
    try
        fig.Position(3:4) = [width height];
    catch
    end
    scale = previewScale(ax, style, width, height);
end

function applyAxesCanvasFrame(ax, width, height)
    if applyGridCanvasFrame(ax, width, height)
        return;
    end
    ratio = width / height;
    margin = 0.07;
    availableWidth = 1 - 2 * margin;
    availableHeight = 1 - 2 * margin;
    frameWidth = availableWidth;
    frameHeight = frameWidth / ratio;
    if frameHeight > availableHeight
        frameHeight = availableHeight;
        frameWidth = frameHeight * ratio;
    end
    left = (1 - frameWidth) / 2;
    bottom = (1 - frameHeight) / 2;
    try
        ax.Units = 'normalized';
        ax.ActivePositionProperty = 'outerposition';
        ax.OuterPosition = [left bottom frameWidth frameHeight];
        ax.Position = [left bottom frameWidth frameHeight];
        scale = min(frameWidth, frameHeight);
        setappdata(ax, 'labkitFigureStudioCanvasFrame', ...
            struct('width', width, 'height', height, ...
            'ratio', ratio, 'position', [left bottom frameWidth frameHeight], ...
            'scale', scale));
    catch
    end
end

function tf = applyGridCanvasFrame(ax, width, height)
    tf = false;
    parent = ax.Parent;
    if isempty(parent) || ~isvalid(parent) || ...
            ~contains(class(parent), 'GridLayout')
        return;
    end
    try
        parentPixels = getpixelposition(parent, true);
        margin = 24;
        availableWidth = max(1, parentPixels(3) - 2 * margin);
        availableHeight = max(1, parentPixels(4) - 2 * margin);
        scale = min(1, min(availableWidth / width, availableHeight / height));
        frameWidth = max(1, round(width * scale));
        frameHeight = max(1, round(height * scale));
        parent.RowHeight = {'1x', frameHeight, '1x'};
        parent.ColumnWidth = {'1x', frameWidth, '1x'};
        setappdata(ax, 'labkitFigureStudioCanvasFrame', ...
            struct('width', width, 'height', height, ...
            'ratio', width / height, ...
            'position', [NaN NaN frameWidth frameHeight], ...
            'scale', scale, ...
            'pixelPosition', [NaN NaN frameWidth frameHeight]));
        tf = true;
    catch
        tf = false;
    end
end

function scale = previewScale(ax, style, width, height)
    scale = 1;
    if ~style.previewScale
        return;
    end
    if isappdata(ax, 'labkitFigureStudioCanvasFrame')
        frame = getappdata(ax, 'labkitFigureStudioCanvasFrame');
        if isfield(frame, 'scale') && isfinite(frame.scale)
            scale = frame.scale;
            return;
        end
    end
    try
        pixelPos = getpixelposition(ax, true);
        scale = min(pixelPos(3) / width, pixelPos(4) / height);
        scale = min(1, max(0.15, scale));
        updateCanvasFrameScale(ax, scale, pixelPos);
    catch
        scale = 1;
    end
end

function updateCanvasFrameScale(ax, scale, pixelPos)
    if ~isappdata(ax, 'labkitFigureStudioCanvasFrame')
        return;
    end
    frame = getappdata(ax, 'labkitFigureStudioCanvasFrame');
    frame.scale = scale;
    frame.pixelPosition = pixelPos;
    setappdata(ax, 'labkitFigureStudioCanvasFrame', frame);
end
