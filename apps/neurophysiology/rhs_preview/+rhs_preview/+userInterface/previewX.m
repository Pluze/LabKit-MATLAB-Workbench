% Expected caller: rhs_preview.definitionActions. Input is the preview axes. Output is the
% current pointer x-coordinate in axes data units, or NaN outside x limits.
function x = previewX(ax)
%PREVIEWX Current x position in preview axes data units.

    point = ax.CurrentPoint;
    x = point(1, 1);
    if isempty(ax.XLim) || x < min(ax.XLim) || x > max(ax.XLim)
        x = NaN;
    end
end
