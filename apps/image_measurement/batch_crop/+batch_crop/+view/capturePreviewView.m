% App-owned preview view helper. Expected caller: batch-crop app redraw logic.
% Inputs are preview axes, current crop geometry, and preview placement. Output
% is a source-coordinate view state used to preserve zoom across redraws.
function state = capturePreviewView(previewAxes, geometry, placement)
%CAPTUREPREVIEWVIEW Capture current preview limits relative to source image.

    state = struct('valid', false);
    if isempty(previewAxes) || ~isvalid(previewAxes) || ...
            ~all(isfinite(previewAxes.XLim)) || ~all(isfinite(previewAxes.YLim))
        return;
    end

    centerCanvas = [mean(previewAxes.XLim), mean(previewAxes.YLim)] - placement.offset;
    centerOriginal = batch_crop.ops.canvasToOriginal(geometry, centerCanvas);
    state = struct( ...
        'valid', true, ...
        'centerOriginal', centerOriginal, ...
        'xSpan', diff(previewAxes.XLim), ...
        'ySpan', diff(previewAxes.YLim));
end
