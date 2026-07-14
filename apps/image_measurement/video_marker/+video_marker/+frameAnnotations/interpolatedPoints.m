%INTERPOLATEDPOINTS Interpolate between nearest bracketing confirmed frames.
% Expected callers are Video Marker actions and tests. Returns an empty point
% array and empty bounds when the current frame is not bracketed by complete
% confirmed annotations. The annotation input is not modified.
function [points, bounds] = interpolatedPoints(annotations, frameIndex)
    frameIndex = round(double(frameIndex));
    confirmed = video_marker.frameAnnotations.statusCode("confirmed");
    before = find(annotations.frameStatus(1:max(0, frameIndex - 1)) == ...
        confirmed, 1, "last");
    afterOffset = find(annotations.frameStatus(min(frameIndex + 1, ...
        numel(annotations.frameStatus)):end) == confirmed, 1, "first");
    points = zeros(0, 2);
    bounds = zeros(1, 0);
    if isempty(before) || isempty(afterOffset) || ...
            frameIndex >= numel(annotations.frameStatus)
        return;
    end
    after = frameIndex + afterOffset;
    firstPoints = video_marker.frameAnnotations.framePoints(annotations, before);
    lastPoints = video_marker.frameAnnotations.framePoints(annotations, after);
    if isempty(firstPoints) || ~isequal(size(firstPoints), size(lastPoints))
        return;
    end
    fraction = (frameIndex - before) / (after - before);
    points = firstPoints + fraction .* (lastPoints - firstPoints);
    bounds = [before after];
end
