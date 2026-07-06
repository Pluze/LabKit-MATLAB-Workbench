% Private scale-bar overlay renderer. Expected caller:
% labkit.ui.interaction.scaleBar.renderOverlay. Inputs are target axes and a prepared
% scale-bar geometry; output is line/text handles or empty. Side effects are
% limited to adding overlay graphics to the target axes.
function handles = drawScaleBarOverlay(ax, scaleBar)
%DRAWSCALEBAROVERLAY Draw a prepared scale-bar geometry onto image axes.
%
% Expected caller:
%   labkit.ui.interaction.scaleBar renderOverlay method.
%
% Inputs/outputs:
%   ax - axes/uiaxes receiving overlay objects.
%   scaleBar - struct returned by the private scaleBarPanel scaleBarGeometry.
%   Returns a struct with line and label graphics handles, or empty when no
%   scale bar is supplied.
%
% Side effects:
%   Adds line/text graphics to ax.

    handles = [];
    if isempty(scaleBar)
        return;
    end

    hLine = plot(ax, scaleBar.line(:, 1), scaleBar.line(:, 2), '-', ...
        'Color', scaleBar.color, ...
        'LineWidth', 3, ...
        'HitTest', 'off', ...
        'PickableParts', 'none', ...
        'DisplayName', 'scale bar');
    hLabel = text(ax, scaleBar.labelPosition(1), scaleBar.labelPosition(2), ...
        scaleBar.label, ...
        'Color', scaleBar.color, ...
        'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', scaleBar.verticalAlignment, ...
        'HitTest', 'off', ...
        'PickableParts', 'none');
    handles = struct('line', hLine, 'label', hLabel);
end
