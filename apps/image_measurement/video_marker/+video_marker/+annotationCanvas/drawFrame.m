%DRAWFRAME Draw one video frame and static annotation overlay.
% Expected caller: Video Marker UI refresh. Inputs are axes, frame image,
% skeleton, annotation struct, and 1-based frame index. Side effects are
% limited to graphics on the provided axes.
function hImage = drawFrame(ui, axesId, frameImage, skeleton, annotations, frameIndex, preserveView)
    if nargin < 7
        preserveView = true;
    end
    hImage = labkit.ui.plot.image(ui, axesId, frameImage, ...
        "title", sprintf('Frame %d', frameIndex), ...
        "options", struct('clearAxes', true, ...
        'reuseImage', true, 'preserveView', logical(preserveView)));
    ax = ancestor(hImage, 'axes');
    video_marker.annotationCanvas.refreshOverlay( ...
        ax, skeleton, annotations, frameIndex);
end
