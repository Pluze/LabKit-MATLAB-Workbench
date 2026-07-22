%REFRESHPREVIEWSCALE Reapply display-only scaling after a preview resize.
% Expected caller is the Figure Studio preview axes SizeChangedFcn. It keeps
% the active interactive viewport and never changes durable style parameters.
function refreshPreviewScale(ax)
if isempty(ax) || ~isvalid(ax) || ...
        ~isappdata(ax, 'labkitFigureStudioPreviewStyle') || ...
        (isappdata(ax, 'labkitFigureStudioPreviewScaling') && ...
        getappdata(ax, 'labkitFigureStudioPreviewScaling'))
    return;
end
style = getappdata(ax, 'labkitFigureStudioPreviewStyle');
if ~isstruct(style)
    return;
end
try
    position = getpixelposition(ax, true);
    size = round(position(3:4));
catch
    return;
end
if isappdata(ax, 'labkitFigureStudioPreviewSize') && ...
        isequal(getappdata(ax, 'labkitFigureStudioPreviewSize'), size)
    return;
end
setappdata(ax, 'labkitFigureStudioPreviewSize', size);
setappdata(ax, 'labkitFigureStudioPreviewScaling', true);
cleanup = onCleanup(@() setappdata( ...
    ax, 'labkitFigureStudioPreviewScaling', false));
viewport = struct("xLim", ax.XLim, "yLim", ax.YLim, ...
    "xMode", ax.XLimMode, "yMode", ax.YLimMode);
style.previewScale = true;
figure_studio.resultFiles.applyFigureStyle(ax, style);
ax.XLim = viewport.xLim;
ax.YLim = viewport.yLim;
ax.XLimMode = viewport.xMode;
ax.YLimMode = viewport.yMode;
clear cleanup
end
