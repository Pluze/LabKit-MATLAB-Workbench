function state = clear(state, context)
%CLEAR Remove every point on the active frame.
if state.session.cache.videoInfo.frameCount <= 0
    return
end
state = video_marker.markerEditing.changePoints(state, zeros(0, 2), context);
end
