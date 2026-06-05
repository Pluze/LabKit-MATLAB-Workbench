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
    hold(ax, 'off');
    ax.XLimMode = 'auto';
    ax.YLimMode = 'auto';
end
