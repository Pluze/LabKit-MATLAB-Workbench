% Expected caller: VT resistance plotting callbacks. Input is one app-owned
% preview axes. Side effects are limited to clearing plotted/annotated graphics
% and restoring automatic axis limits.
function clearPlotAxis(ax)
%CLEARPLOTAXIS Remove all VT preview plot graphics from an axes.

    delete(allchild(ax));
    cla(ax);
    hold(ax, 'off');
    ax.XLimMode = 'auto';
    ax.YLimMode = 'auto';
end
