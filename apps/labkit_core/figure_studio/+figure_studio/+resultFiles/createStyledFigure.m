% Expected caller: Figure Studio export actions. Inputs are a serializable
% plot model and style. Outputs are an invisible temporary figure and axes.
function [fig, ax] = createStyledFigure(plotData, style)
    fig = figure('Visible', 'off', 'Color', 'w');
    ax = axes('Parent', fig);
    model = struct("plotData", plotData, "style", style, "preview", false);
    figure_studio.sourceAxes.drawPreview(struct("main", ax), model);
end
