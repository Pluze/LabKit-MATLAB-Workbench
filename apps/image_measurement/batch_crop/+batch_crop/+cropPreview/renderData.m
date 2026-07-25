% App-owned preview rendering helper. Expected caller: batch-crop preview
% redraw logic. Inputs are the full crop geometry and placement metadata.
% Output preserves full canvas coordinate extents. Callers may explicitly
% request a lower CData budget; ordinary Batch Crop previews retain the canvas
% resolution selected by cropGeometry.currentGeometry.
function render = renderData(geometry, placement, opts)
%PREVIEWRENDERDATA Prepare a lightweight preview image for axes rendering.

    if nargin < 3
        opts = struct();
    end

    canvas = geometry.canvas;
    scaleFactor = 1;
    if isstruct(opts) && isfield(opts, 'MaxPreviewPixels') && ...
            ~isempty(opts.MaxPreviewPixels)
        [canvas, info] = labkit.image.previewBudget(geometry.canvas, ...
            "MaxPixels", opts.MaxPreviewPixels);
        scaleFactor = info.scaleFactor;
    end

    render = struct( ...
        'imageData', canvas, ...
        'xData', placement.xData, ...
        'yData', placement.yData, ...
        'scaleFactor', scaleFactor);
end
