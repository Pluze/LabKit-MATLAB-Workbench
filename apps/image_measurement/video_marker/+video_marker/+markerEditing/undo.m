function state = undo(state, context)
%UNDO Remove the last point on the active frame.
points = video_marker.markerEditing.currentPoints(state);
if isempty(points)
    return
end
points(end, :) = [];
state = video_marker.markerEditing.changePoints(state, points, context);
end
