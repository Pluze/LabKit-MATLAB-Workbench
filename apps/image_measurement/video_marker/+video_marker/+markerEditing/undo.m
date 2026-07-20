function state = undo(state, context)
%UNDO Remove the last point on the active frame.
points = video_marker.markerEditing.currentPoints(state);
if isempty(points)
    return
end
points(end, :) = [];
frame = state.session.cache.frameIndex;
state = video_marker.markerEditing.setPoints(state, points);
context.appendStatus("Undid last point on frame " + string(frame) + ".");
end
