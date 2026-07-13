% App-owned preview rendering helper. Expected caller: batch-crop preview
% redraw logic. Inputs are the full crop geometry and placement metadata.
% Output preserves full canvas coordinate extents while optionally lowering
% preview CData resolution for responsive GUI rendering.
function render = previewRenderData(geometry, placement, opts)
%PREVIEWRENDERDATA Prepare a lightweight preview image for axes rendering.

    if nargin < 3
        opts = struct();
    end

    maxPreviewPixels = double(optionValue(opts, 'MaxPreviewPixels', ...
        defaultPreviewPixels()));
    if ~isfinite(maxPreviewPixels) || maxPreviewPixels < 1
        maxPreviewPixels = defaultPreviewPixels();
    end

    [canvas, info] = labkit.image.previewBudget(geometry.canvas, ...
        "MaxPixels", maxPreviewPixels);

    render = struct( ...
        'imageData', canvas, ...
        'xData', placement.xData, ...
        'yData', placement.yData, ...
        'scaleFactor', info.scaleFactor);
end

function value = defaultPreviewPixels()
    % Constant: 1.2 megapixels balances draggable preview responsiveness
    % with sufficient crop-placement detail.
    value = 1.2e6;
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end
