% Expected caller: Figure Studio export actions. Inputs are a serializable
% plot model and style. Outputs are an invisible temporary figure and axes.
function [fig, ax] = createStyledFigure(plotData, style, sourceAxes)
%CREATESTYLEDFIGURE Build a styled export from native or portable graphics.
if nargin < 3
    sourceAxes = [];
end
    fig = figure('Visible', 'off', 'Color', 'w', ...
        'MenuBar', 'none', 'ToolBar', 'none');
    useNativeSource = ~isempty(sourceAxes) && isscalar(sourceAxes) && ...
        isgraphics(sourceAxes, "axes") && ...
        ~isa(sourceAxes, 'matlab.ui.control.UIAxes');
    if useNativeSource
        ax = copyobj(sourceAxes, fig);
        figure_studio.sourceAxes.copyLegend(sourceAxes, ax);
        applyStoredLimits(ax, plotData);
        applyStoredTicks(ax, plotData);
        figure_studio.resultFiles.applyFigureStyle(ax, style);
        return;
    end
    if isa(sourceAxes, 'matlab.ui.control.UIAxes')
        plotData = portableUiAxesData(plotData);
    end
    ax = axes('Parent', fig);
    model = struct("plotData", plotData, "sourceAxes", [], ...
        "style", style, "preview", false);
    figure_studio.sourceAxes.drawPreview(struct("main", ax), model);
end

function plotData = portableUiAxesData(plotData)
% UIAxes stores screen-derived aspect vectors that cannot be applied to a
% conventional export axes with a fixed publication plot frame. The Figure
% Studio frame therefore owns that geometry; data, limits, labels, ticks, and
% scientific ruler exponents remain in the portable snapshot.
if ~isstruct(plotData) || ~isfield(plotData, 'axes') || ...
        ~isstruct(plotData.axes)
    return;
end
names = {'dataAspectRatio', 'dataAspectRatioMode', ...
    'plotBoxAspectRatio', 'plotBoxAspectRatioMode'};
names = names(isfield(plotData.axes, names));
if ~isempty(names)
    plotData.axes = rmfield(plotData.axes, names);
end
end

function applyStoredTicks(ax, plotData)
if ~isstruct(plotData) || ~isfield(plotData, "axes") || ...
        ~isstruct(plotData.axes)
    return;
end
metadata = plotData.axes;
if isfield(metadata, "xTick")
    ax.XTick = metadata.xTick;
end
if isfield(metadata, "yTick")
    ax.YTick = metadata.yTick;
end
if isfield(metadata, "zTick")
    ax.ZTick = metadata.zTick;
end
if isfield(metadata, "xTickLabel")
    ax.XTickLabel = metadata.xTickLabel;
end
if isfield(metadata, "yTickLabel")
    ax.YTickLabel = metadata.yTickLabel;
end
if isfield(metadata, "zTickLabel")
    ax.ZTickLabel = metadata.zTickLabel;
end
end

function applyStoredLimits(ax, plotData)
if ~isstruct(plotData) || ~isfield(plotData, "axes")
    return;
end
for field = ["xLim", "yLim"]
    if ~isfield(plotData.axes, field)
        continue;
    end
    value = double(plotData.axes.(field));
    if numel(value) == 2 && all(isfinite(value)) && value(1) < value(2)
        property = upper(extractBefore(field, 2)) + "Lim";
        ax.(char(property)) = reshape(value, 1, 2);
    end
end
end
