% Read style defaults from a source axes for Figure Studio. Expected caller is
% Figure Studio direct callbacks; output follows the app-owned style struct.
function style = sourceStyle(srcAx, opts)
    arguments
        srcAx
        opts.PreserveAspect (1, 1) logical = true
    end

    style = figure_studio.styleLibrary.styleForPreset("FIG default");
    style.name = "FIG default";
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
    width = 720;
    height = 540;
    if isfinite(ratio) && ratio > 0
        height = max(300, round(width / ratio));
    end
    style.canvasWidth = width;
    style.canvasHeight = height;
    style.fontName = string(optionalAxesValue(srcAx, 'FontName'));
    if strlength(style.fontName) == 0
        style.fontName = "Arial";
    end
    style.baseFontSize = finiteValue(optionalAxesValue(srcAx, 'FontSize'), 36);
    style.titleFontSize = sourceLabelFont(srcAx.Title, style.baseFontSize);
    style.labelFontSize = max([sourceLabelFont(srcAx.XLabel, style.baseFontSize), ...
        sourceLabelFont(srcAx.YLabel, style.baseFontSize), ...
        sourceLabelFont(srcAx.ZLabel, style.baseFontSize)]);
    style.tickFontSize = style.baseFontSize;
    style.dataLineWidth = sourceDataLineWidth(srcAx, 1.5);
    style.axesLineWidth = finiteValue(optionalAxesValue(srcAx, 'LineWidth'), 1.25);
    style.gridVisible = string(optionalAxesValue(srcAx, 'XGrid')) == "on" || ...
        string(optionalAxesValue(srcAx, 'YGrid')) == "on";
    style.gridAlpha = finiteValue(optionalAxesValue(srcAx, 'GridAlpha'), 0.12);
    style.boxVisible = string(optionalAxesValue(srcAx, 'Box')) == "on";
    style.boundaryLines = style.boxVisible;
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

function value = sourceDataLineWidth(ax, fallback)
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
