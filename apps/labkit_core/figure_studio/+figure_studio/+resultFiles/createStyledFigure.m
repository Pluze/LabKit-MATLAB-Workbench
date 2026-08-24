% Expected caller: Figure Studio export actions. Inputs are a serializable
% plot model and style. Outputs are an invisible temporary figure and axes.
function [fig, ax] = createStyledFigure(plotData, style, sourceAxes)
%CREATESTYLEDFIGURE Build an export through the same renderer as the preview.
if nargin < 3
    sourceAxes = [];
end
    fig = figure('Visible', 'off', 'Color', 'w', ...
        'MenuBar', 'none', 'ToolBar', 'none');
    if isa(sourceAxes, 'matlab.ui.control.UIAxes')
        plotData = portableUiAxesData(plotData);
        sourceAxes = [];
    end
    ax = axes('Parent', fig);
    model = struct("plotData", plotData, "sourceAxes", sourceAxes, ...
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
