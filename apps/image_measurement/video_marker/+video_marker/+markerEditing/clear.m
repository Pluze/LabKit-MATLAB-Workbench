function state = clear(state, context)
%CLEAR Remove every point on the active frame.
if state.session.cache.videoInfo.frameCount <= 0
    return
end
frame = state.session.cache.frameIndex;
state = video_marker.markerEditing.setPoints(state, zeros(0, 2));
context.appendStatus("Cleared frame " + string(frame) + " points.");
end
