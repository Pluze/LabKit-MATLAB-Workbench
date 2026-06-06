% Expected caller: DIC preprocess runner. Inputs are image-space coordinates and
% image size. Output indicates whether the point is within the displayed image
% bounds. Side effects: none.

function tf = insideImageBounds(x, y, imageSize)
%INSIDEIMAGEBOUNDS Test whether image-space coordinates are inside image bounds.

    tf = isfinite(x) && isfinite(y) && ...
        x >= 0.5 && y >= 0.5 && ...
        x <= imageSize(2) + 0.5 && y <= imageSize(1) + 0.5;
end
