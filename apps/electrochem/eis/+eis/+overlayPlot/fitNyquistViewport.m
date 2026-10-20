function fitNyquistViewport(ax)
% Extend coordinate limits rather than shrinking an equal-unit plot box.
labkit.app.plot.fitAxesToGraphics(ax, EqualDataUnits=true);
fillPlotBox(ax);
% This single-axis App plot owns its panel's resize; leave figure callbacks alone.
panel = ancestor(ax, 'uipanel');
if ~isempty(panel)
    panel.AutoResizeChildren = 'off';
    panel.SizeChangedFcn = @(~, ~) fillPlotBox(ax);
end
end

function fillPlotBox(ax)
busyKey = 'eisNyquistResizing';
if ~isgraphics(ax) || (isappdata(ax, busyKey) && getappdata(ax, busyKey)), return; end
setappdata(ax, busyKey, true);
cleanup = onCleanup(@() setappdata(ax, busyKey, false));
x = ax.XLim;
y = ax.YLim;
center = [mean(x), mean(y)];
baseSpan = [diff(x), diff(y)];
previousRatio = NaN;
% Tick-label and side-legend margins can change as limits expand. Resolve
% their small layout feedback with bounded, damped updates from one viewport.
for iteration = 1:12
    drawnow limitrate nocallbacks;
    position = getpixelposition(ax);
    allocation = ax.Position;
    inner = ax.InnerPosition;
    if any(allocation(3:4) <= 0) || any(inner(3:4) <= 0), return; end
    pixels = inner(3:4) .* position(3:4) ./ allocation(3:4);
    ratio = pixels(1)/pixels(2);
    if abs(log((diff(ax.XLim)/diff(ax.YLim))/ratio)) < .002, break; end
    if isfinite(previousRatio), ratio = sqrt(ratio * previousRatio); end
    ySpan = max(baseSpan(2), baseSpan(1)/ratio);
    xlim(ax, center(1) + [-.5 .5] * ySpan * ratio);
    ylim(ax, center(2) + [-.5 .5] * ySpan);
    previousRatio = ratio;
end
clear cleanup
end
