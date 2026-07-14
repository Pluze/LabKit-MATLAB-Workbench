% Expected caller: DIC preprocess preview-wheel callbacks. Inputs are the
% target axes and MATLAB wheel event. Side effect: applies cursor-centered
% zoom to that axes; no app semantic state is changed.
function zoomPreviewAtPointer(ax, event)

    point = ax.CurrentPoint;
    labkit.ui.interaction.zoomAtPoint(ax, point(1, 1:2), ...
        event.VerticalScrollCount);
end
