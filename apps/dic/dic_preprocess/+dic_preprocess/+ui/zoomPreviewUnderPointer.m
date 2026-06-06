% Expected caller: DIC preprocess runner. Inputs are figure, preview axes, and
% a scroll event. Side effect: zooms the preview axes under the pointer.

function zoomPreviewUnderPointer(fig, topAxes, bottomAxes, evt)
%ZOOMPREVIEWUNDERPOINTER Apply scroll-wheel zoom to the pointed DIC preview axes.

    ax = dic_preprocess.ui.previewAxesUnderPointer(fig, topAxes, bottomAxes);
    if isempty(ax)
        return;
    end

    point = ax.CurrentPoint;
    x = point(1, 1);
    y = point(1, 2);
    imageSize = dic_preprocess.ui.axesImageSize(ax);
    if isempty(imageSize) || ~dic_preprocess.ui.insideImageBounds(x, y, imageSize)
        return;
    end
    dic_preprocess.ui.zoomAxesAtPoint(ax, x, y, evt.VerticalScrollCount, imageSize);
end
