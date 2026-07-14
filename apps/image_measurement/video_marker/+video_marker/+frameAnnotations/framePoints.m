%FRAMEPOINTS Return the ordered finite point prefix for one frame.
% Expected caller: point editor activation, inherit, export, and tests.
function points = framePoints(annotations, frameIndex)
    frameIndex = round(double(frameIndex));
    xy = squeeze(annotations.coords(frameIndex, :, :));
    if isempty(xy)
        points = zeros(0, 2);
        return;
    end
    if size(xy, 1) == 2 && size(annotations.coords, 2) ~= 2
        xy = xy.';
    end
    finiteRows = all(isfinite(xy), 2);
    firstMissing = find(~finiteRows, 1);
    if isempty(firstMissing)
        points = xy;
    else
        points = xy(1:firstMissing-1, :);
    end
end
