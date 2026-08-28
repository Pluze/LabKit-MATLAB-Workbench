function position = normalizePosition(position, shape, imageSize)
%NORMALIZEPOSITION Clamp a rectangle-like ROI to the image pixel domain.
position = double(position(:).');
if numel(position) ~= 4 || any(~isfinite(position))
    position = [NaN NaN NaN NaN];
    return
end
height = double(imageSize(1));
width = double(imageSize(2));
position(3:4) = max(position(3:4), 1);
if string(shape) == "Square" || string(shape) == "Circle"
    side = min(position(3:4));
    center = position(1:2) + position(3:4) ./ 2;
    position = [center - side ./ 2, side, side];
end
position(3) = min(position(3), width);
position(4) = min(position(4), height);
position(1) = min(max(position(1), 1), max(1, width - position(3) + 1));
position(2) = min(max(position(2), 1), max(1, height - position(4) + 1));
end
