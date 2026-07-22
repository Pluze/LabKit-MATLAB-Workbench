%VISUALMETRICS Measure one rendered single-panel figure in display pixels.
% Expected callers are Figure Studio visual-regression tests and diagnostic
% scripts. The input is a drawn axes. The output reports the plot frame,
% title/label/tick scale, and stroke scale relative to the rendered canvas;
% it does not alter the figure, axes, or durable Figure Studio project.
function metrics = visualMetrics(ax)
%VISUALMETRICS Return normalized pixel-scale metrics for a rendered axes.
if isempty(ax) || ~isscalar(ax) || ~isvalid(ax)
    error("figure_studio:styleLibrary:InvalidAxes", ...
        "Visual metrics require one valid axes handle.");
end
fig = ancestor(ax, "figure");
if isempty(fig) || ~isvalid(fig)
    error("figure_studio:styleLibrary:MissingFigure", ...
        "Visual metrics require an axes with a valid parent figure.");
end
drawnow nocallbacks
figureUnits = fig.Units;
axesUnits = ax.Units;
cleanup = onCleanup(@() restoreUnits(fig, ax, figureUnits, axesUnits));
fig.Units = 'pixels';
ax.Units = 'pixels';
canvas = fig.Position;
frame = ax.Position;
if canvas(3) <= 0 || canvas(4) <= 0 || frame(3) <= 0 || frame(4) <= 0
    error("figure_studio:styleLibrary:InvalidPixelGeometry", ...
        "Visual metrics require positive figure and axes pixel geometry.");
end
pointToPixel = double(get(groot, "ScreenPixelsPerInch")) / 72;
titleHeight = textHeight(ax.Title);
xLabelHeight = textHeight(ax.XLabel);
yLabelHeight = textHeight(ax.YLabel);
dataWidths = visibleDataLineWidths(ax);
metrics = struct( ...
    "canvasPixels", canvas(3:4), ...
    "axesPixels", frame(3:4), ...
    "frameToCanvas", [frame(1) / canvas(3), frame(2) / canvas(4), ...
        frame(3) / canvas(3), frame(4) / canvas(4)], ...
    "titleHeightToPlot", titleHeight / frame(4), ...
    "xLabelHeightToPlot", xLabelHeight / frame(4), ...
    "yLabelHeightToPlot", yLabelHeight / frame(4), ...
    "tickHeightToPlot", ax.FontSize * pointToPixel / frame(4), ...
    "axesStrokeToPlot", ax.LineWidth * pointToPixel / min(frame(3:4)), ...
    "dataStrokeToPlot", median(dataWidths) * pointToPixel / min(frame(3:4)));
clear cleanup
end

function restoreUnits(fig, ax, figureUnits, axesUnits)
if isvalid(fig)
    fig.Units = figureUnits;
end
if isvalid(ax)
    ax.Units = axesUnits;
end
end

function height = textHeight(handle)
height = 0;
if isempty(handle) || ~isvalid(handle)
    return;
end
units = handle.Units;
cleanup = onCleanup(@() set(handle, "Units", units));
handle.Units = "pixels";
extent = handle.Extent;
height = max(0, double(extent(4)));
clear cleanup
end

function widths = visibleDataLineWidths(ax)
children = findall(ax, "-property", "LineWidth");
widths = zeros(numel(children), 1);
count = 0;
for index = 1:numel(children)
    child = children(index);
    if child == ax || ~isvalid(child)
        continue;
    end
    type = lower(string(child.Type));
    if ~any(type == ["line", "scatter", "surface"])
        continue;
    end
    if isprop(child, "Visible") && string(child.Visible) == "off"
        continue;
    end
    count = count + 1;
    widths(count) = double(child.LineWidth);
end
widths = widths(1:count);
if count == 0
    widths = NaN;
end
end
