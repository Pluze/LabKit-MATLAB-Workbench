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
%       titleFontSize, labelFontSize, tickFontSize, annotationFontSize,
%       dataLineWidth, uncertaintyLineWidth, boundaryLineWidth,
%       referenceLineWidth, axesLineWidth,
%       gridAlpha, gridVisible, boxVisible,
%       boundaryLines, legendTokenWidth, canvasWidth, canvasHeight,
%       referenceCanvasWidth,
%       referenceCanvasHeight, previewScale, legend controls, and colorOrder
%       fields.
%
% Output:
%   None. The copied graphics state is changed in place.
%
% Behavior:
%   Uses editable sans-serif text and applies semantic text and stroke
%   categories. Canvas values describe the inner plot frame, not the outer
%   figure. Category sizes scale with that frame relative to the style's
%   reference frame; export calculates outer text margins from rendered
%   labels, ticks, title, and annotations.

    if nargin < 2
        preset = "nature";
    end
    if isempty(ax) || ~isvalid(ax)
        error('figure_studio:resultFiles:InvalidAxes', ...
            'Axes handle is not valid.');
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
    style = scaledStyle(style, canvasStyleScale(style));
    viewScale = applyPreviewGeometry(ax, style);
    style = scaledStyle(style, viewScale);
    ax.FontName = char(style.fontName);
    ax.FontSize = style.tickFontSize;
    ax.LineWidth = style.axesLineWidth;
    ax.Box = onOff(style.boundaryLines);
    ax.TickDir = char(style.tickDirection);
    ax.ColorOrder = style.colorOrder;
    applyTickLabelAngle(ax, style.xTickLabelAngle);
    if style.gridVisible
        grid(ax, 'on');
        ax.GridAlpha = style.gridAlpha;
    else
        grid(ax, 'off');
    end
    styleLabels(ax);
    styleLabelsFromStyle(ax, style);
    styleDataChildren(ax, style);
    unifyAnnotationFont(ax, style);
    styleLegend(ax, style);
    layoutExportCanvas(ax, style);
end

function style = defaultNatureStyle()
    style = struct( ...
        "fontName", preferredFont(), ...
        "baseFontSize", 12, ...
        "titleFontSize", 14, ...
        "labelFontSize", 12, ...
        "tickFontSize", 11, ...
        "annotationFontSize", 10, ...
        "xTickLabelAngle", "Source", ...
        "dataLineWidth", 1.75, ...
        "uncertaintyLineWidth", 1.25, ...
        "boundaryLineWidth", 1.25, ...
        "referenceLineWidth", 1.25, ...
        "axesLineWidth", 1.5, ...
        "gridAlpha", 0.12, ...
        "gridVisible", false, ...
        "boxVisible", false, ...
        "boundaryLines", false, ...
        "legendVisible", "Source", ...
        "legendLocation", "Source", ...
        "legendFontSize", 10, ...
        "legendTokenWidth", 0, ...
        "legendNumColumns", 0, ...
        "legendBox", "Source", ...
        "canvasWidth", 900, ...
        "canvasHeight", 725, ...
        "referenceCanvasWidth", 900, ...
        "referenceCanvasHeight", 725, ...
        "previewScale", false, ...
        "tickDirection", "out", ...
        "axesPosition", [], ...
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
    style.annotationFontSize = finiteScalar(style.annotationFontSize, ...
        defaults.annotationFontSize);
    style.dataLineWidth = finiteScalar(style.dataLineWidth, defaults.dataLineWidth);
    style.uncertaintyLineWidth = finiteScalar( ...
        style.uncertaintyLineWidth, defaults.uncertaintyLineWidth);
    style.boundaryLineWidth = finiteScalar(style.boundaryLineWidth, ...
        defaults.boundaryLineWidth);
    style.referenceLineWidth = finiteScalar(style.referenceLineWidth, ...
        defaults.referenceLineWidth);
    style.axesLineWidth = finiteScalar(style.axesLineWidth, defaults.axesLineWidth);
    style.legendFontSize = finiteScalar(style.legendFontSize, ...
        defaults.legendFontSize);
    style.legendTokenWidth = max(0, finiteScalar( ...
        style.legendTokenWidth, defaults.legendTokenWidth));
    style.legendNumColumns = max(0, round(finiteScalar( ...
        style.legendNumColumns, defaults.legendNumColumns)));
    style.gridAlpha = min(max(finiteScalar(style.gridAlpha, defaults.gridAlpha), 0), 1);
    style.gridVisible = logical(style.gridVisible);
    style.boxVisible = logical(style.boxVisible);
    style.boundaryLines = logical(style.boundaryLines);
    style.canvasWidth = finiteScalar(style.canvasWidth, defaults.canvasWidth);
    style.canvasHeight = finiteScalar(style.canvasHeight, defaults.canvasHeight);
    style.referenceCanvasWidth = finiteScalar( ...
        style.referenceCanvasWidth, style.canvasWidth);
    style.referenceCanvasHeight = finiteScalar( ...
        style.referenceCanvasHeight, style.canvasHeight);
    style.previewScale = logical(style.previewScale);
end

function scale = canvasStyleScale(style)
    scale = min( ...
        style.canvasWidth / max(style.referenceCanvasWidth, 1), ...
        style.canvasHeight / max(style.referenceCanvasHeight, 1));
    scale = min(16, max(0.1, scale));
end

function style = scaledStyle(style, scale)
    style.titleFontSize = max(1, style.titleFontSize * scale);
    style.labelFontSize = max(1, style.labelFontSize * scale);
    style.tickFontSize = max(1, style.tickFontSize * scale);
    style.annotationFontSize = max(1, style.annotationFontSize * scale);
    style.legendFontSize = max(1, style.legendFontSize * scale);
    style.legendTokenWidth = max(0, style.legendTokenWidth * scale);
    style.dataLineWidth = max(0.1, style.dataLineWidth * scale);
    style.uncertaintyLineWidth = max(0.1, ...
        style.uncertaintyLineWidth * scale);
    style.boundaryLineWidth = max(0.1, ...
        style.boundaryLineWidth * scale);
    style.referenceLineWidth = max(0.1, ...
        style.referenceLineWidth * scale);
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
    preferred = ["Helvetica", "Arial", "Liberation Sans", "DejaVu Sans"];
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
        kind = graphicStrokeKind(child);
        switch kind
            case "data"
                child.LineWidth = style.dataLineWidth;
            case "boundary"
                child.LineWidth = style.boundaryLineWidth;
            case "reference"
                child.LineWidth = style.referenceLineWidth;
            case "uncertainty"
                child.LineWidth = style.uncertaintyLineWidth;
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

function kind = graphicStrokeKind(handle)
    kind = "";
    try
        type = lower(string(handle.Type));
    catch
        return;
    end
    if type == "line" && preserveSourceLineWidth(handle)
        return;
    elseif any(type == ["line", "scatter", "surface"])
        kind = "data";
    elseif type == "errorbar"
        kind = "uncertainty";
    elseif any(type == ["bar", "area", "patch", "rectangle"])
        kind = "boundary";
    elseif type == "constantline"
        kind = "reference";
    end
end

function tf = preserveSourceLineWidth(handle)
    tf = false;
    try
        if string(handle.HandleVisibility) == "off"
            tf = true;
            return;
        end
        xData = handle.XData;
        yData = handle.YData;
        tf = numel(xData) <= 2 || numel(yData) <= 2;
    catch
    end
end

function unifyAnnotationFont(ax, style)
    labels = {ax.Title, ax.XLabel, ax.YLabel, ax.ZLabel};
    texts = findall(ax, 'Type', 'text');
    for k = 1:numel(texts)
        if any(cellfun(@(label) texts(k) == label, labels))
            continue;
        end
        texts(k).FontName = char(style.fontName);
        texts(k).FontSize = style.annotationFontSize;
    end
    references = findall(ax, 'Type', 'constantline');
    for k = 1:numel(references)
        if isprop(references(k), 'FontName')
            references(k).FontName = char(style.fontName);
        end
        if isprop(references(k), 'FontSize')
            references(k).FontSize = style.annotationFontSize;
        end
    end
end

function applyTickLabelAngle(ax, choice)
    switch string(choice)
        case "Horizontal"
            ax.XTickLabelRotation = 0;
        case "45 deg"
            ax.XTickLabelRotation = 45;
    end
end

function value = onOff(tf)
    if tf
        value = 'on';
    else
        value = 'off';
    end
end

function styleLegend(ax, style)
    lgd = [];
    if isprop(ax, 'Legend')
        lgd = ax.Legend;
    end
    if isempty(lgd) && string(style.legendVisible) == "On"
        try
            lgd = legend(ax, 'show');
        catch
            return;
        end
    end
    if isempty(lgd) || ~isvalid(lgd)
        return;
    end
    lgd.FontName = ax.FontName;
    lgd.FontSize = style.legendFontSize;
    if style.legendTokenWidth > 0 && isprop(lgd, 'ItemTokenSize')
        tokenSize = lgd.ItemTokenSize;
        tokenSize(1) = style.legendTokenWidth;
        lgd.ItemTokenSize = tokenSize;
    end
    if string(style.legendVisible) ~= "Source"
        lgd.Visible = lower(char(style.legendVisible));
    end
    if string(style.legendLocation) ~= "Source"
        lgd.Location = char(style.legendLocation);
    end
    if style.legendNumColumns > 0 && isprop(lgd, 'NumColumns')
        lgd.NumColumns = round(style.legendNumColumns);
    end
    if string(style.legendBox) ~= "Source"
        lgd.Box = lower(char(style.legendBox));
    end
end

function scale = applyPreviewGeometry(ax, style)
    width = max(1, double(style.canvasWidth));
    height = max(1, double(style.canvasHeight));
    fig = ancestor(ax, 'figure');
    if isempty(fig) || ~isvalid(fig) || style.previewScale || ...
            isa(ax, 'matlab.ui.control.UIAxes')
        applyPreviewCanvasAspect(ax, style, width, height);
        scale = previewScale(ax, style, width, height);
        return;
    end
    scale = 1;
end

function applyPreviewCanvasAspect(ax, style, width, height)
if ~style.previewScale
    return;
end
try
    ax.PlotBoxAspectRatio = [width height 1];
    ax.PlotBoxAspectRatioMode = 'manual';
catch
end
end

function scale = previewScale(ax, style, width, height)
    scale = 1;
    if ~style.previewScale
        return;
    end
    try
        pixelPos = getpixelposition(ax, true);
        scale = min(pixelPos(3) / width, pixelPos(4) / height);
        scale = min(1, max(0.15, scale));
    catch
        scale = 1;
    end
end

function layoutExportCanvas(ax, style)
if style.previewScale || isa(ax, 'matlab.ui.control.UIAxes')
    return;
end
fig = ancestor(ax, 'figure');
if isempty(fig) || ~isvalid(fig)
    return;
end
try
    originalFigureUnits = fig.Units;
    originalAxesUnits = ax.Units;
    cleanup = onCleanup(@() restoreLayoutUnits( ...
        fig, ax, originalFigureUnits, originalAxesUnits));
    plotWidth = max(1, round(double(style.canvasWidth)));
    plotHeight = max(1, round(double(style.canvasHeight)));
    % Keep a release-independent safety margin around font extents. Older
    % Windows renderers can report a title several pixels wider only after
    % the final draw.
    padding = max(16, round(0.01 * min(plotWidth, plotHeight)));
    fig.Units = 'pixels';
    ax.Units = 'pixels';
    setFigureContentSize(fig, [plotWidth + 4 * padding, ...
        plotHeight + 4 * padding]);
    ax.Position = [2 * padding 2 * padding plotWidth plotHeight];
    for iteration = 1:3
        drawnow nocallbacks
        inset = plotInsets(ax, plotWidth, plotHeight, padding);
        setFigureContentSize(fig, [ ...
            inset(1) + plotWidth + inset(3), ...
            inset(2) + plotHeight + inset(4)]);
        ax.Position = [inset(1) inset(2) plotWidth plotHeight];
    end
    clear cleanup
catch
end
end

function setFigureContentSize(fig, sizePixels)
% Position includes native window decorations on desktop MATLAB. Axes pixel
% coordinates live in the drawable client area, so size that area directly;
% otherwise a title bar silently removes height from the requested frame.
if isprop(fig, 'InnerPosition')
    position = fig.InnerPosition;
    position(3:4) = sizePixels;
    fig.InnerPosition = position;
else
    position = fig.Position;
    position(3:4) = sizePixels;
    fig.Position = position;
end
end

function inset = plotInsets(ax, plotWidth, plotHeight, padding)
inset = [padding padding padding padding];
try
    tight = double(ax.TightInset);
    if numel(tight) == 4 && all(isfinite(tight))
        inset = max(inset, reshape(tight, 1, 4) + padding);
    end
catch
end
textInset = textExtentsOutsidePlot(ax, plotWidth, plotHeight);
inset = max(inset, textInset + padding);
end

function inset = textExtentsOutsidePlot(ax, plotWidth, plotHeight)
inset = zeros(1, 4);
texts = findall(ax, 'Type', 'text');
for index = 1:numel(texts)
    textHandle = texts(index);
    if ~isvalid(textHandle) || string(textHandle.Visible) == "off"
        continue;
    end
    try
        units = textHandle.Units;
        cleanup = onCleanup(@() set(textHandle, 'Units', units));
        textHandle.Units = 'pixels';
        extent = double(textHandle.Extent);
        if numel(extent) ~= 4 || any(~isfinite(extent)) || ...
                extent(3) <= 0 || extent(4) <= 0
            clear cleanup
            continue;
        end
        inset = max(inset, [ ...
            max(0, -extent(1)), ...
            max(0, -extent(2)), ...
            max(0, extent(1) + extent(3) - plotWidth), ...
            max(0, extent(2) + extent(4) - plotHeight)]);
        clear cleanup
    catch
    end
end
end

function restoreLayoutUnits(fig, ax, figureUnits, axesUnits)
if isvalid(fig)
    fig.Units = figureUnits;
end
if isvalid(ax)
    ax.Units = axesUnits;
end
end
