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
    if style.manageCanvas
        viewScale = applyPreviewGeometry(ax, style);
    else
        viewScale = 1;
    end
    style = scaledStyle(style, viewScale);
    ax.FontName = char(style.fontName);
    ax.FontSize = style.tickFontSize;
    ax.LineWidth = style.axesLineWidth;
    ax.Box = onOff(style.boundaryLines);
    ax.TickDir = char(style.tickDirection);
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
    unifyAnnotationFont(ax, style);
    reflowComparisonAnnotations(ax, style);
    applyTickLabelLayout(ax, style);
    styleLegend(ax, style);
    if style.manageCanvas
        layoutExportCanvas(ax, style);
    end
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
        "wrapXTickLabels", false, ...
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
        "manageCanvas", true, ...
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
    style.wrapXTickLabels = logical(style.wrapXTickLabels);
    style.canvasWidth = finiteScalar(style.canvasWidth, defaults.canvasWidth);
    style.canvasHeight = finiteScalar(style.canvasHeight, defaults.canvasHeight);
    style.referenceCanvasWidth = finiteScalar( ...
        style.referenceCanvasWidth, style.canvasWidth);
    style.referenceCanvasHeight = finiteScalar( ...
        style.referenceCanvasHeight, style.canvasHeight);
    style.previewScale = logical(style.previewScale);
    style.manageCanvas = logical(style.manageCanvas);
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
                if lower(string(child.Type)) == "bar"
                    standardizeBarAppearance(child, style);
                end
            case "reference"
                child.LineWidth = style.referenceLineWidth;
            case "uncertainty"
                child.LineWidth = style.uncertaintyLineWidth;
        end
    end
end

function standardizeBarAppearance(barHandle, style)
    count = numel(barHandle.YData);
    if count < 1 || isempty(style.colorOrder)
        return;
    end
    indices = mod((0:(count - 1)), size(style.colorOrder, 1)) + 1;
    try
        barHandle.CData = style.colorOrder(indices, :);
        barHandle.FaceColor = "none";
        barHandle.EdgeColor = "flat";
        barHandle.FaceAlpha = 1;
    catch
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
    if type == "line" && hiddenFromLegend(handle)
        kind = "reference";
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

function tf = hiddenFromLegend(handle)
    tf = false;
    try
        tf = string(handle.HandleVisibility) == "off";
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

function reflowComparisonAnnotations(ax, style)
    brackets = findall(ax, "Type", "line", "HandleVisibility", "off");
    if isempty(brackets)
        return;
    end
    axisLabels = [ax.Title, ax.XLabel, ax.YLabel, ax.ZLabel];
    texts = findall(ax, "Type", "text");
    texts = texts(~arrayfun(@(value) any(value == axisLabels), texts));
    if isempty(texts)
        return;
    end
    xLimits = double(ax.XLim);
    yLimits = double(ax.YLim);
    xRange = max(diff(xLimits), eps);
    yRange = max(diff(yLimits), eps);
    dpi = 96;
    try
        dpi = double(get(groot, "ScreenPixelsPerInch"));
    catch
    end
    if ~isscalar(dpi) || ~isfinite(dpi) || dpi <= 0
        dpi = 96;
    end
    fontHeight = yRange * style.annotationFontSize * dpi / ...
        (72 * max(style.canvasHeight, 1));
    textGap = 0.82 * fontHeight;
    requiredTop = yLimits(2);
    used = false(size(texts));
    for bracket = reshape(brackets, 1, [])
        x = double(bracket.XData(:).');
        y = double(bracket.YData(:).');
        if numel(x) ~= 4 || numel(y) ~= 4 || ...
                abs(x(1) - x(2)) > eps(xRange) || ...
                abs(x(3) - x(4)) > eps(xRange) || ...
                abs(y(1) - y(4)) > eps(yRange) || ...
                abs(y(2) - y(3)) > eps(yRange) || y(2) <= y(1)
            continue;
        end
        center = 0.5 * (x(1) + x(3));
        top = y(2);
        scores = inf(size(texts));
        for k = 1:numel(texts)
            if used(k)
                continue;
            end
            position = double(texts(k).Position);
            if numel(position) < 2 || any(~isfinite(position(1:2)))
                continue;
            end
            scores(k) = abs(position(1) - center) / xRange + ...
                abs(position(2) - top) / yRange;
        end
        [score, index] = min(scores);
        if isempty(index) || ~isfinite(score) || score > 0.25
            continue;
        end
        position = texts(index).Position;
        position(2) = top + textGap;
        texts(index).Position = position;
        texts(index).VerticalAlignment = "bottom";
        used(index) = true;
        requiredTop = max(requiredTop, position(2) + 1.1 * fontHeight);
    end
    if requiredTop > yLimits(2)
        ax.YLim = [yLimits(1), requiredTop + 0.06 * yRange];
    end
end

function applyTickLabelLayout(ax, style)
    tag = "figureStudioWrappedXTickLabel";
    sourceKey = "figureStudioSourceXTickLabel";
    delete(findall(ax, "Type", "text", "Tag", tag));
    if isappdata(ax, sourceKey)
        sourceLabels = string(getappdata(ax, sourceKey));
    else
        sourceLabels = string(ax.XTickLabel);
    end
    switch string(style.xTickLabelAngle)
        case "Horizontal"
            ax.XTickLabelRotation = 0;
        case "45 deg"
            ax.XTickLabelRotation = 45;
    end
    if style.wrapXTickLabels
        ticks = double(ax.XTick(:));
        labels = sourceLabels(:);
        count = min(numel(ticks), numel(labels));
        setappdata(ax, sourceKey, cellstr(sourceLabels));
        ax.XTickLabel = repmat({''}, size(ax.XTickLabel));
        y = ax.YLim(1);
        for k = 1:count
            label = balancedTwoLineLabel(labels(k));
            text(ax, ticks(k), y, label, ...
                "HorizontalAlignment", "center", ...
                "VerticalAlignment", "top", ...
                "Interpreter", "none", ...
                "FontName", char(style.fontName), ...
                "FontSize", style.tickFontSize, ...
                "Clipping", "off", "HitTest", "off", ...
                "PickableParts", "none", "HandleVisibility", "off", ...
                "Tag", tag);
        end
        ax.XTickLabelRotation = 0;
    elseif isappdata(ax, sourceKey)
        ax.XTickLabel = cellstr(sourceLabels);
        rmappdata(ax, sourceKey);
    end
end

function label = balancedTwoLineLabel(label)
    words = split(strip(label));
    words(words == "") = [];
    if numel(words) < 2
        return;
    end
    bestIndex = 1;
    bestDifference = Inf;
    for index = 1:(numel(words) - 1)
        first = join(words(1:index), " ");
        second = join(words(index + 1:end), " ");
        difference = abs(strlength(first) - strlength(second));
        if difference < bestDifference
            bestDifference = difference;
            bestIndex = index;
        end
    end
    label = join(words(1:bestIndex), " ") + newline + ...
        join(words(bestIndex + 1:end), " ");
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
    applyCanvasAspect(ax, width, height);
    fig = ancestor(ax, 'figure');
    if isempty(fig) || ~isvalid(fig) || style.previewScale || ...
            isa(ax, 'matlab.ui.control.UIAxes')
        scale = previewScale(ax, style, width, height);
        return;
    end
    scale = 1;
end

function applyCanvasAspect(ax, width, height)
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
    padding = exportOuterPadding(style, plotWidth, plotHeight);
    fig.Units = 'pixels';
    ax.Units = 'pixels';
    setFigureContentSize(fig, [plotWidth + 4 * padding, ...
        plotHeight + 4 * padding]);
    ax.Position = [2 * padding 2 * padding plotWidth plotHeight];
    % Font extents can change after the native renderer accepts a larger
    % offscreen window. Iterate to a stable geometry instead of assuming a
    % fixed number of draw/resize passes across releases and platforms.
    for iteration = 1:8
        drawnow nocallbacks
        inset = plotInsets(ax, plotWidth, plotHeight, padding);
        targetFigureSize = [ ...
            inset(1) + plotWidth + inset(3), ...
            inset(2) + plotHeight + inset(4)];
        targetAxesPosition = [inset(1) inset(2) plotWidth plotHeight];
        currentFigurePosition = fig.Position;
        if max(abs(currentFigurePosition(3:4) - targetFigureSize)) < 0.5 && ...
                max(abs(ax.Position - targetAxesPosition)) < 0.5
            break;
        end
        setFigureContentSize(fig, targetFigureSize);
        ax.Position = targetAxesPosition;
    end
    fitPlotFrameWithinAcceptedCanvas( ...
        fig, ax, plotWidth, plotHeight, padding);
    fitRenderedTextWithinFigure(fig, ax, padding);
    clear cleanup
catch
end
end

function padding = exportOuterPadding(style, plotWidth, plotHeight)
% Keep a renderer-independent half-em of whitespace outside labels and ticks.
% Windows print releases also need one complete hardcopy line box because
% their pre-print screen extent can omit that much of an axis label.
padding = max(4, round(0.01 * min(plotWidth, plotHeight)));
dpi = 96;
try
    dpi = double(get(groot, 'ScreenPixelsPerInch'));
catch
end
if ~isscalar(dpi) || ~isfinite(dpi) || dpi <= 0
    dpi = 96;
end
labelEmPixels = max([style.labelFontSize style.tickFontSize]) * dpi / 72;
marginInEms = 0.5;
if ispc && isMATLABReleaseOlderThan("R2025a")
    marginInEms = 1.5;
end
padding = max(padding, ceil(marginInEms * labelEmPixels));
end

function fitPlotFrameWithinAcceptedCanvas( ...
        fig, ax, plotWidth, plotHeight, padding)
% A Windows desktop can refuse the requested outer figure size. Recompute the
% data frame from the accepted drawable canvas and the measured outer insets;
% the App must reserve label whitespace rather than render into a clipped page.
for iteration = 1:4
    drawnow nocallbacks
    inset = plotInsets(ax, plotWidth, plotHeight, padding);
    accepted = double(fig.Position(3:4));
    available = max(1, accepted - [ ...
        inset(1) + inset(3), inset(2) + inset(4)]);
    fitted = min([plotWidth plotHeight], available);
    target = [inset(1) inset(2) fitted];
    if max(abs(double(ax.Position) - target)) < 0.5
        break;
    end
    ax.Position = target;
end
end

function setFigureContentSize(fig, sizePixels)
% Windows constrains displayed windows to the desktop, while an invisible
% figure can exceed the screen for export. Anchor that hidden canvas before
% assigning its drawable Position so the window manager does not clamp a
% large canvas at the default on-screen location.
position = fig.Position;
if string(fig.Visible) == "off"
    position(1:2) = [1 1];
end
position(3:4) = sizePixels;
fig.Position = position;
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
texts = axesTextHandles(ax);
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

function fitRenderedTextWithinFigure(fig, ax, padding)
% Older Windows renderers can update text extents only after accepting the
% final offscreen figure geometry. Measure the rendered figure-coordinate
% bounds and grow only the sides that still overflow.
for iteration = 1:4
    drawnow nocallbacks
    overflow = renderedTextOverflow(fig, ax, padding);
    if max(overflow) < 0.5
        break;
    end
    figurePosition = fig.Position;
    setFigureContentSize(fig, [ ...
        figurePosition(3) + overflow(1) + overflow(3), ...
        figurePosition(4) + overflow(2) + overflow(4)]);
    axesPosition = ax.Position;
    axesPosition(1:2) = axesPosition(1:2) + overflow(1:2);
    ax.Position = axesPosition;
end
% Residual renderer rounding can remain after the accepted-canvas fit.
shiftRenderedTextInsideFigure(fig, ax, padding);
drawnow nocallbacks
end

function overflow = renderedTextOverflow(fig, ax, padding)
overflow = zeros(1, 4);
figurePosition = fig.Position;
axesPosition = ax.Position;
texts = axesTextHandles(ax);
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
        if numel(extent) == 4 && all(isfinite(extent)) && ...
                extent(3) > 0 && extent(4) > 0
            bounds = [ ...
                axesPosition(1) + extent(1), ...
                axesPosition(2) + extent(2), ...
                axesPosition(1) + extent(1) + extent(3), ...
                axesPosition(2) + extent(2) + extent(4)];
            overflow = max(overflow, [ ...
                max(0, padding - bounds(1)), ...
                max(0, padding - bounds(2)), ...
                max(0, bounds(3) + padding - figurePosition(3)), ...
                max(0, bounds(4) + padding - figurePosition(4))]);
        end
        clear cleanup
    catch
    end
end
end

function shiftRenderedTextInsideFigure(fig, ax, padding)
figureSize = double(fig.Position(3:4));
axesPosition = double(ax.Position);
texts = axesTextHandles(ax);
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
        position = double(textHandle.Position);
        if numel(extent) ~= 4 || any(~isfinite(extent)) || ...
                numel(position) < 2 || any(~isfinite(position(1:2))) || ...
                extent(3) <= 0 || extent(4) <= 0
            clear cleanup
            continue;
        end
        bounds = [ ...
            axesPosition(1) + extent(1), ...
            axesPosition(2) + extent(2), ...
            axesPosition(1) + extent(1) + extent(3), ...
            axesPosition(2) + extent(2) + extent(4)];
        availablePadding = min([padding padding], ...
            max(0, (figureSize - extent(3:4)) ./ 2));
        lower = availablePadding;
        upper = figureSize - availablePadding;
        delta = max(0, lower - bounds(1:2));
        delta = delta - max(0, bounds(3:4) + delta - upper);
        if any(abs(delta) >= 0.5)
            position(1:2) = position(1:2) + delta;
            textHandle.Position = position;
        end
        clear cleanup
    catch
    end
end
end

function texts = axesTextHandles(ax)
% R2022b does not consistently expose ruler decorators as descendants of the
% axes. Include them explicitly, then add ordinary annotation text.
labels = [ax.Title; ax.XLabel; ax.YLabel; ax.ZLabel];
ordinary = findall(ax, 'Type', 'text');
keep = true(size(ordinary));
for index = 1:numel(ordinary)
    keep(index) = ~any(ordinary(index) == labels);
end
texts = [labels; ordinary(keep)];
end

function restoreLayoutUnits(fig, ax, figureUnits, axesUnits)
if isvalid(fig)
    fig.Units = figureUnits;
end
if isvalid(ax)
    ax.Units = axesUnits;
end
end
