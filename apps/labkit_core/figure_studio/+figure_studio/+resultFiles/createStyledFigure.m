% Expected caller: Figure Studio export actions. Inputs are a serializable
% plot model and style. Outputs are an invisible temporary figure and axes.
function [fig, ax] = createStyledFigure(plotData, style, sourceAxes, document)
%CREATESTYLEDFIGURE Build a styled export from native or portable graphics.
if nargin < 3
    sourceAxes = [];
end
if nargin < 4
    document = [];
end
    if ~isempty(document) && numel(document.panels) > 1
        [fig, ax] = createDocumentFigure(document, style);
        return;
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
        if ~isempty(document)
            figure_studio.figureDocument.applyToAxes(document, "", ax);
        end
        return;
    end
    if isa(sourceAxes, 'matlab.ui.control.UIAxes')
        plotData = portableUiAxesData(plotData);
    end
    ax = axes('Parent', fig);
    model = struct("plotData", plotData, "sourceAxes", [], ...
        "document", document, "panelId", "", ...
        "style", style, "preview", false);
    figure_studio.sourceAxes.drawPreview(struct("main", ax), model);
end

function [fig, axesValues] = createDocumentFigure(document, style)
fig = figure('Visible', 'off', 'Color', document.canvas.background, ...
    'MenuBar', 'none', 'ToolBar', 'none', 'Units', 'pixels');
fig.Position(3:4) = [document.canvas.width document.canvas.height];
padding = double(document.canvas.padding);
content = [padding(1), padding(4), ...
    max(1, document.canvas.width - padding(1) - padding(2)), ...
    max(1, document.canvas.height - padding(3) - padding(4))];
axesValues = gobjects(numel(document.panels), 1);
for k = 1:numel(document.panels)
    panel = document.panels(k);
    geometry = panel.geometry;
    position = [content(1) + geometry(1) * content(3), ...
        content(2) + geometry(2) * content(4), ...
        geometry(3) * content(3), geometry(4) * content(4)];
    ax = axes('Parent', fig, 'Units', 'pixels', 'Position', position);
    panelStyle = style;
    panelStyle.canvasWidth = position(3);
    panelStyle.canvasHeight = position(4);
    panelStyle.previewScale = false;
    panelStyle.manageCanvas = false;
    plotData = figure_studio.figureDocument.toPlotData(document, panel.id);
    model = struct("plotData", plotData, "sourceAxes", [], ...
        "document", document, "panelId", panel.id, ...
        "style", panelStyle, "preview", false);
    figure_studio.sourceAxes.drawPreview(struct("main", ax), model);
    ax.Units = 'pixels';
    ax.Position = position;
    axesValues(k) = ax;
end
applySharedAxes(document.panels, axesValues);
fig.Position(3:4) = [document.canvas.width document.canvas.height];
end

function applySharedAxes(panels, axesValues)
for field = ["sharedXGroup", "sharedYGroup"]
    groups = unique(string({panels.(char(field))}));
    groups(groups == "") = [];
    dimension = extractBetween(field, 7, 7);
    for group = reshape(groups, 1, [])
        indices = string({panels.(char(field))}) == group;
        if sum(indices) > 1
            linkaxes(axesValues(indices), char(lower(dimension)));
        end
    end
end
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
