%INHERITDRAFT Copy the nearest previous confirmed frame into a draft frame.
% Expected caller: frame navigation and tests. Existing confirmed frames are
% not overwritten unless force is true.
function annotations = inheritDraft(annotations, frameIndex, force)
    if nargin < 3
        force = false;
    end
    frameIndex = round(double(frameIndex));
    confirmed = video_marker.frameAnnotations.statusCode("confirmed");
    if ~force && annotations.frameStatus(frameIndex) == confirmed
        return;
    end
    previous = find(annotations.frameStatus(1:max(0, frameIndex-1)) == confirmed, 1, "last");
    if isempty(previous)
        return;
    end
    points = video_marker.frameAnnotations.framePoints(annotations, previous);
    if isempty(points)
        return;
    end
    annotations = video_marker.frameAnnotations.setFramePoints( ...
        annotations, frameIndex, points, "draft", "predicted", ...
        zeros(size(points, 1), 1));
end
