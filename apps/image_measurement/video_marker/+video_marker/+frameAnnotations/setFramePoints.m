%SETFRAMEPOINTS Store points for one frame and mark it draft or confirmed.
% Expected caller: point editor callbacks and tests. Points are ordered rows.
function annotations = setFramePoints(annotations, frameIndex, points, statusName)
    frameIndex = round(double(frameIndex));
    pointCount = size(annotations.coords, 2);
    points = double(points);
    if size(points, 2) ~= 2 || size(points, 1) > pointCount
        error('labkit_VideoMarker_app:InvalidPoints', 'Points must be K-by-2 with K no larger than the skeleton point count.');
    end
    if any(~isfinite(points(:)))
        error('labkit_VideoMarker_app:InvalidPoints', 'Placed points must be finite.');
    end
    if string(statusName) == "confirmed" && size(points, 1) ~= pointCount
        error('labkit_VideoMarker_app:IncompleteFrame', 'Confirmed frames must contain every keypoint.');
    end
    annotations.coords(frameIndex, :, :) = NaN;
    if ~isempty(points)
        annotations.coords(frameIndex, 1:size(points, 1), 1) = points(:, 1);
        annotations.coords(frameIndex, 1:size(points, 1), 2) = points(:, 2);
    end
    if isempty(points)
        statusName = "empty";
    end
    annotations.frameStatus(frameIndex) = video_marker.frameAnnotations.statusCode(statusName);
end
