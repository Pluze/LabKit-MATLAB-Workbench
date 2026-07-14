%AVAILABILITY Report whether interpolation and previous-frame tracking can run.
% Expected callers are Video Marker control rendering and suggestion actions.
function available = availability(state)
    available = struct('interpolate', false, 'trackPrevious', false);
    if state.videoInfo.frameCount <= 0
        return;
    end
    [points, ~] = video_marker.frameAnnotations.interpolatedPoints( ...
        state.annotations, state.currentFrame);
    available.interpolate = ~isempty(points);
    if state.currentFrame <= 1
        return;
    end
    confirmed = video_marker.frameAnnotations.statusCode("confirmed");
    previousPoints = video_marker.frameAnnotations.framePoints( ...
        state.annotations, state.currentFrame - 1);
    available.trackPrevious = ...
        state.annotations.frameStatus(state.currentFrame - 1) == confirmed && ...
        size(previousPoints, 1) == numel(state.skeleton.pointIds);
end
