% Private UI view helper. Expected caller: labkit.ui.view panel, control,
% plot, or text facades. Inputs and outputs are internal UI handles, labels,
% selections, table data, or plot info. Side effects are limited to supplied UI
% parents or axes; assumes the caller owns callbacks and app state.
function clearAxes(ax)
%CLEARAXES Remove plotted children without resetting axes configuration.
%
% Inputs:
%   ax - target axes.
%
% Output:
%   Deletes current axes children and restores hold off / auto limits.

    if ~isempty(ax.Children)
        delete(ax.Children);
    end
    clearImageViewState(ax);
    hold(ax, 'off');
    ax.XLimMode = 'auto';
    ax.YLimMode = 'auto';
end

function clearImageViewState(ax)
    key = 'labkitImageViewBounds';
    if isappdata(ax, key)
        rmappdata(ax, key);
    end
end
