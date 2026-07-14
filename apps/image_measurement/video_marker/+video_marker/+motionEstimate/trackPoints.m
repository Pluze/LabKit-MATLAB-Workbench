%TRACKPOINTS Estimate current point locations by local grayscale block matching.
% Expected caller: Video Marker previous-frame tracking action. Inputs are two
% same-sized image frames and N-by-2 [x y] points in the first frame. Output
% keeps point order and applies an integer local displacement to each point.
function points = trackPoints(previousImage, currentImage, previousPoints)
    previous = grayDouble(previousImage);
    current = grayDouble(currentImage);
    if ~isequal(size(previous), size(current))
        error('labkit_VideoMarker_app:FrameSizeMismatch', ...
            'Motion estimation requires consecutive frames with the same size.');
    end
    previousPoints = double(previousPoints);
    if size(previousPoints, 2) ~= 2 || any(~isfinite(previousPoints(:)))
        error('labkit_VideoMarker_app:InvalidTrackingPoints', ...
            'Previous-frame points must be a finite N-by-2 array.');
    end

    % Constant: a 9-by-9 patch captures local texture without smoothing over
    % small joint motion in typical video-resolution animal recordings.
    patchRadius = 4;
    % Constant: a 25-by-25 search window bounds per-point cost while covering
    % ordinary inter-frame treadmill motion at common acquisition rates.
    searchRadius = 12;
    points = previousPoints;
    for k = 1:size(previousPoints, 1)
        points(k, :) = trackOne(previous, current, previousPoints(k, :), ...
            patchRadius, searchRadius);
    end
end

function point = trackOne(previous, current, sourcePoint, patchRadius, searchRadius)
    height = size(previous, 1);
    width = size(previous, 2);
    sourceX = min(max(1, round(sourcePoint(1))), width);
    sourceY = min(max(1, round(sourcePoint(2))), height);
    left = min(patchRadius, sourceX - 1);
    right = min(patchRadius, width - sourceX);
    top = min(patchRadius, sourceY - 1);
    bottom = min(patchRadius, height - sourceY);
    reference = previous(sourceY - top:sourceY + bottom, ...
        sourceX - left:sourceX + right);

    xCandidates = max(1 + left, sourceX - searchRadius): ...
        min(width - right, sourceX + searchRadius);
    yCandidates = max(1 + top, sourceY - searchRadius): ...
        min(height - bottom, sourceY + searchRadius);
    bestScore = -Inf;
    bestDistance = Inf;
    best = [sourceX sourceY];
    for y = yCandidates
        for x = xCandidates
            candidate = current(y - top:y + bottom, x - left:x + right);
            score = similarity(reference, candidate);
            distance = (x - sourceX)^2 + (y - sourceY)^2;
            if score > bestScore || (score == bestScore && distance < bestDistance)
                bestScore = score;
                bestDistance = distance;
                best = [x y];
            end
        end
    end
    point = sourcePoint + (best - [sourceX sourceY]);
end

function score = similarity(a, b)
    a = a - mean(a, 'all');
    b = b - mean(b, 'all');
    denominator = sqrt(sum(a.^2, 'all') * sum(b.^2, 'all'));
    if denominator > eps
        score = sum(a .* b, 'all') / denominator;
    else
        score = -mean((a - b).^2, 'all');
    end
end

function image = grayDouble(image)
    if ndims(image) == 3
        image = labkit.image.rgb2gray(image);
    end
    image = labkit.image.im2double(image);
end
