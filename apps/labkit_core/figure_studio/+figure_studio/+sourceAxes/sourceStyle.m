% Read style defaults from a source axes for Figure Studio. Expected caller is
% Figure Studio direct callbacks; output follows the app-owned style struct.
function style = sourceStyle(srcAx, opts)
    arguments
        srcAx
        opts.PreserveAspect (1, 1) logical = true
    end

    style = figure_studio.styleLibrary.styleForPreset("FIG default");
    style.name = "FIG default";
    style.axesPosition = [];
    if isempty(srcAx) || ~isvalid(srcAx)
        return;
    end
    if opts.PreserveAspect
        ratio = ratioFromVector(optionalAxesValue(srcAx, 'PlotBoxAspectRatio'));
        if ~isfinite(ratio)
            ratio = ratioFromPosition(srcAx);
        end
    else
        ratio = ratioFromPosition(srcAx);
        if ~isfinite(ratio)
            ratio = ratioFromVector(optionalAxesValue(srcAx, 'PlotBoxAspectRatio'));
        end
    end
    [width, height] = sourceCanvasSize(srcAx, ratio);
    style.canvasWidth = width;
    style.canvasHeight = height;
    style.referenceCanvasWidth = width;
    style.referenceCanvasHeight = height;
    style.fontName = string(optionalAxesValue(srcAx, 'FontName'));
    if strlength(style.fontName) == 0
        style.fontName = "Arial";
    end
    style.baseFontSize = finiteValue(optionalAxesValue( ...
        srcAx, 'FontSize'), style.baseFontSize);
    style.titleFontSize = sourceLabelFont(srcAx.Title, style.baseFontSize);
    style.labelFontSize = max([sourceLabelFont(srcAx.XLabel, style.baseFontSize), ...
        sourceLabelFont(srcAx.YLabel, style.baseFontSize), ...
        sourceLabelFont(srcAx.ZLabel, style.baseFontSize)]);
    style.tickFontSize = style.baseFontSize;
    style.annotationFontSize = sourceAnnotationFontSize(srcAx, ...
        style.annotationFontSize);
    style.xTickLabelAngle = sourceTickAngle(srcAx);
    style.dataLineWidth = sourceLineWidth(srcAx, ...
        ["line", "scatter", "surface"], style.dataLineWidth);
    style.uncertaintyLineWidth = sourceLineWidth(srcAx, ...
        "errorbar", style.uncertaintyLineWidth);
    style.boundaryLineWidth = sourceLineWidth(srcAx, ...
        ["bar", "area", "patch", "rectangle"], ...
        style.boundaryLineWidth);
    style.referenceLineWidth = sourceLineWidth(srcAx, ...
        "constantline", style.referenceLineWidth);
    style.axesLineWidth = finiteValue(optionalAxesValue( ...
        srcAx, 'LineWidth'), style.axesLineWidth);
    style.gridVisible = string(optionalAxesValue(srcAx, 'XGrid')) == "on" || ...
        string(optionalAxesValue(srcAx, 'YGrid')) == "on";
    style.gridAlpha = finiteValue(optionalAxesValue(srcAx, 'GridAlpha'), 0.12);
    style.boxVisible = string(optionalAxesValue(srcAx, 'Box')) == "on";
    style.boundaryLines = style.boxVisible;
    style = sourceLegendStyle(srcAx, style);
end

function [width, height] = sourceCanvasSize(ax, ratio)
width = 720;
height = 540;
try
    figureHandle = ancestor(ax, "figure");
    position = getpixelposition(figureHandle, true);
    if numel(position) == 4 && all(isfinite(position(3:4))) && ...
            all(position(3:4) > 0)
        width = round(position(3));
        height = round(position(4));
    end
catch
end
if isfinite(ratio) && ratio > 0
    height = max(240, round(width / ratio));
end
width = min(max(width, 320), 8000);
height = min(max(height, 240), 8000);
end

function value = sourceLabelFont(labelHandle, fallback)
    value = fallback;
    try
        if ~isempty(labelHandle) && isvalid(labelHandle)
            value = finiteValue(labelHandle.FontSize, fallback);
        end
    catch
    end
end

function value = sourceLineWidth(ax, types, fallback)
    value = fallback;
    try
        children = findall(ax, '-property', 'LineWidth');
        widths = nan(numel(children), 1);
        count = 0;
        for k = 1:numel(children)
            child = children(k);
            if isempty(child) || ~isvalid(child) || child == ax
                continue;
            end
            try
                if ~any(lower(string(child.Type)) == lower(string(types)))
                    continue;
                end
                count = count + 1;
                widths(count) = double(child.LineWidth);
            catch
            end
        end
        widths = widths(1:count);
        widths = widths(isfinite(widths));
        if ~isempty(widths)
            value = median(widths);
        end
    catch
    end
end

function value = sourceAnnotationFontSize(ax, fallback)
    value = fallback;
    labels = {ax.Title, ax.XLabel, ax.YLabel, ax.ZLabel};
    texts = findall(ax, 'Type', 'text');
    sizes = zeros(0, 1);
    for k = 1:numel(texts)
        if any(cellfun(@(label) texts(k) == label, labels))
            continue;
        end
        sizeValue = finiteValue(optionalAxesValue( ...
            texts(k), 'FontSize'), NaN);
        if isfinite(sizeValue)
            sizes(end + 1, 1) = sizeValue;
        end
    end
    if ~isempty(sizes)
        value = median(sizes);
    end
end

function choice = sourceTickAngle(ax)
    angle = finiteValue(optionalAxesValue(ax, 'XTickLabelRotation'), NaN);
    if angle == 0
        choice = "Horizontal";
    elseif angle == 45
        choice = "45 deg";
    else
        choice = "Source";
    end
end

function style = sourceLegendStyle(ax, style)
    if ~isprop(ax, 'Legend') || isempty(ax.Legend) || ~isvalid(ax.Legend)
        return;
    end
    lgd = ax.Legend;
    style.legendVisible = titleCase(optionalAxesValue(lgd, 'Visible'));
    style.legendLocation = string(optionalAxesValue(lgd, 'Location'));
    style.legendFontSize = finiteValue(optionalAxesValue( ...
        lgd, 'FontSize'), style.legendFontSize);
    style.legendNumColumns = finiteValue(optionalAxesValue( ...
        lgd, 'NumColumns'), style.legendNumColumns);
    style.legendBox = titleCase(optionalAxesValue(lgd, 'Box'));
end

function value = titleCase(value)
    value = lower(string(value));
    if value == "on"
        value = "On";
    elseif value == "off"
        value = "Off";
    else
        value = "Source";
    end
end

function ratio = ratioFromVector(value)
    ratio = NaN;
    if isnumeric(value) && numel(value) >= 2 && ...
            all(isfinite(value(1:2))) && value(2) > 0
        ratio = double(value(1)) / double(value(2));
    end
end

function ratio = ratioFromPosition(ax)
    ratio = NaN;
    try
        pos = getpixelposition(ax, true);
        if numel(pos) >= 4 && all(isfinite(pos(3:4))) && pos(4) > 0
            ratio = double(pos(3)) / double(pos(4));
        end
    catch
    end
end

function value = optionalAxesValue(ax, prop)
    value = [];
    try
        value = ax.(prop);
    catch
    end
end

function value = finiteValue(value, fallback)
    value = double(value);
    if ~isscalar(value) || ~isfinite(value)
        value = fallback;
    end
end
