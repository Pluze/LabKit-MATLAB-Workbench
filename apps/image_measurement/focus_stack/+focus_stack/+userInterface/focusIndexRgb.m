% App-owned focus-stack preview color helper. Expected caller:
% labkit_FocusStack_app preview refresh. Inputs are focus index map and image
% count. Output is an RGB double image. This helper has no side effects.
function rgb = focusIndexRgb(focusIndex, imageCount)
%FOCUSINDEXRGB Convert focus-index map to an RGB preview image.

    imageCount = max(1, double(imageCount));
    cmap = parula(max(imageCount, 2));
    idx = double(focusIndex);
    idx(~isfinite(idx) | idx < 1) = 1;
    idx(idx > imageCount) = imageCount;
    rgb = zeros(size(idx, 1), size(idx, 2), 3);
    for k = 1:imageCount
        mask = idx == k;
        for c = 1:3
            channel = rgb(:, :, c);
            channel(mask) = cmap(k, c);
            rgb(:, :, c) = channel;
        end
    end
end
