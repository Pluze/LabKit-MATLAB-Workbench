function zoomPreviewAtPointer(ax, event)
%ZOOMPREVIEWATPOINTER Apply cursor-centered wheel zoom to one preview axes.

    point = ax.CurrentPoint;
    labkit.ui.interaction.zoomAtPoint(ax, point(1, 1:2), ...
        event.VerticalScrollCount);
end
