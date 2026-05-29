function clearAxisObjects(ax)
%CLEARAXISOBJECTS Remove plotted children without resetting axes configuration.

    if ~isempty(ax.Children)
        delete(ax.Children);
    end
    hold(ax, 'off');
    ax.XLimMode = 'auto';
    ax.YLimMode = 'auto';
end
