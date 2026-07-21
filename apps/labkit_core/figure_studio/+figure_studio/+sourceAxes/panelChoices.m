%PANELCHOICES Return visible FIG axes in reading order and their labels.
% Expected callers: Figure Studio source import and panel selection. Input is
% a vector of candidate axes. Output excludes legends and orders each real
% plotting panel from top-left to bottom-right without modifying the figure.
function [axesHandles, labels] = panelChoices(axesHandles)
arguments
    axesHandles
end
axesHandles = axesHandles(isgraphics(axesHandles, "axes"));
axesHandles = axesHandles(~isLegendAxes(axesHandles));
if isempty(axesHandles)
    labels = strings(1, 0);
    return;
end

positions = zeros(numel(axesHandles), 2);
for k = 1:numel(axesHandles)
    positions(k, :) = panelPosition(axesHandles(k));
end
[~, order] = sortrows([-positions(:, 2), positions(:, 1)], [1 2]);
axesHandles = axesHandles(order);
labels = strings(1, numel(axesHandles));
for k = 1:numel(axesHandles)
    titleText = panelTitle(axesHandles(k));
    labels(k) = "Panel " + string(k);
    if strlength(titleText) > 0
        labels(k) = labels(k) + " — " + titleText;
    end
end
end

function tf = isLegendAxes(axesHandles)
tags = strings(size(axesHandles));
for k = 1:numel(axesHandles)
    try
        tags(k) = string(axesHandles(k).Tag);
    catch
    end
end
tf = tags == "legend";
end

function position = panelPosition(ax)
try
    pixelPosition = getpixelposition(ax, true);
    position = pixelPosition(1:2);
catch
    position = ax.Position(1:2);
end
end

function value = panelTitle(ax)
value = "";
try
    value = strtrim(join(string(ax.Title.String), " "));
    value = replace(value, newline, " ");
catch
end
end
