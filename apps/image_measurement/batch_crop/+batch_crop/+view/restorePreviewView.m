% App-owned preview view helper. Expected caller: batch-crop app redraw logic.
% Inputs are preview axes, a captured view state, crop geometry, and placement.
% Side effect is limited to restoring axes limits when the state is valid.
function restorePreviewView(previewAxes, state, geometry, placement)
%RESTOREPREVIEWVIEW Restore source-coordinate preview limits after redraw.

    if isempty(state) || ~isstruct(state) || ~isfield(state, 'valid') || ~state.valid
        return;
    end
    if ~isfinite(state.xSpan) || ~isfinite(state.ySpan) || ...
            state.xSpan <= 0 || state.ySpan <= 0
        return;
    end

    centerCanvas = batch_crop.ops.originalToCanvas(geometry, state.centerOriginal) + ...
        placement.offset;
    previewAxes.XLim = centeredLimits(centerCanvas(1), state.xSpan, ...
        imageDataLimits(placement.xData, size(geometry.canvas, 2)));
    previewAxes.YLim = centeredLimits(centerCanvas(2), state.ySpan, ...
        imageDataLimits(placement.yData, size(geometry.canvas, 1)));
end

function limits = centeredLimits(center, span, fullLimits)
    fullSpan = diff(fullLimits);
    if span >= fullSpan
        limits = fullLimits;
        return;
    end
    limits = center + [-0.5, 0.5] .* span;
    if limits(1) < fullLimits(1)
        limits = [fullLimits(1), fullLimits(1) + span];
    end
    if limits(2) > fullLimits(2)
        limits = [fullLimits(2) - span, fullLimits(2)];
    end
end

function limits = imageDataLimits(data, count)
    data = double(data(:)).';
    if numel(data) < 2 || count <= 1
        limits = data(1) + [-0.5, 0.5];
        return;
    end
    step = abs(diff(data(1:2))) / max(1, count - 1);
    limits = sort(data(1:2)) + [-0.5, 0.5] .* step;
end
