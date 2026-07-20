% App-owned preview view helper. Expected caller: batch-crop app redraw logic.
% Inputs are preview axes, a captured view state, crop geometry, and placement.
% Side effect is limited to restoring axes limits when the state is valid.
function restoreView(previewAxes, state, geometry, placement)
%RESTOREPREVIEWVIEW Restore source-coordinate preview limits after redraw.

    if isempty(state) || ~isstruct(state) || ~isfield(state, 'valid') || ~state.valid
        return;
    end
    if ~hasOriginalLimits(state) && (~isfinite(state.xSpan) || ~isfinite(state.ySpan) || ...
            state.xSpan <= 0 || state.ySpan <= 0)
        return;
    end

    fullXLimits = imageDataLimits(placement.xData, size(geometry.canvas, 2));
    fullYLimits = imageDataLimits(placement.yData, size(geometry.canvas, 1));
    if hasOriginalCorners(state)
        cornersCanvas = zeros(size(state.originalCorners));
        for k = 1:size(state.originalCorners, 1)
            cornersCanvas(k, :) = batch_crop.cropGeometry.originalToCanvas(geometry, ...
                state.originalCorners(k, :)) + placement.offset;
        end
        previewAxes.XLim = clampLimits([min(cornersCanvas(:, 1)), ...
            max(cornersCanvas(:, 1))], fullXLimits);
        previewAxes.YLim = clampLimits([min(cornersCanvas(:, 2)), ...
            max(cornersCanvas(:, 2))], fullYLimits);
        return;
    end
    if hasOriginalLimits(state)
        previewAxes.XLim = clampLimits(originalAxisLimits(geometry, placement, ...
            state.originalXLim, 1), fullXLimits);
        previewAxes.YLim = clampLimits(originalAxisLimits(geometry, placement, ...
            state.originalYLim, 2), fullYLimits);
        return;
    end

    centerCanvas = batch_crop.cropGeometry.originalToCanvas(geometry, state.centerOriginal) + ...
        placement.offset;
    previewAxes.XLim = centeredLimits(centerCanvas(1), state.xSpan, fullXLimits);
    previewAxes.YLim = centeredLimits(centerCanvas(2), state.ySpan, fullYLimits);
end

function tf = hasOriginalCorners(state)
    tf = isfield(state, 'originalCorners') && isnumeric(state.originalCorners) && ...
        isequal(size(state.originalCorners), [4 2]) && ...
        all(isfinite(state.originalCorners), "all");
end

function tf = hasOriginalLimits(state)
    tf = isfield(state, 'originalXLim') && isfield(state, 'originalYLim') && ...
        numel(state.originalXLim) == 2 && numel(state.originalYLim) == 2 && ...
        all(isfinite(state.originalXLim)) && all(isfinite(state.originalYLim)) && ...
        diff(state.originalXLim) > 0 && diff(state.originalYLim) > 0;
end

function limits = originalAxisLimits(geometry, placement, originalLimits, axisIndex)
    if axisIndex == 1
        firstPoint = [originalLimits(1), geometry.sourceHeight / 2];
        secondPoint = [originalLimits(2), geometry.sourceHeight / 2];
    else
        firstPoint = [geometry.sourceWidth / 2, originalLimits(1)];
        secondPoint = [geometry.sourceWidth / 2, originalLimits(2)];
    end
    firstCanvas = batch_crop.cropGeometry.originalToCanvas(geometry, firstPoint) + placement.offset;
    secondCanvas = batch_crop.cropGeometry.originalToCanvas(geometry, secondPoint) + placement.offset;
    limits = sort([firstCanvas(axisIndex), secondCanvas(axisIndex)]);
end

function limits = clampLimits(limits, fullLimits)
    span = diff(limits);
    fullSpan = diff(fullLimits);
    if span >= fullSpan
        limits = fullLimits;
        return;
    end
    if limits(1) < fullLimits(1)
        limits = [fullLimits(1), fullLimits(1) + span];
    end
    if limits(2) > fullLimits(2)
        limits = [fullLimits(2) - span, fullLimits(2)];
    end
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
