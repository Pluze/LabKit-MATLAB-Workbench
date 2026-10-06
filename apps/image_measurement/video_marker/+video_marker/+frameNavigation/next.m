function state = next(state, context)
%NEXT Move to the next video frame.
state = video_marker.frameNavigation.changeFrame( ...
    state, state.session.cache.frameIndex + 1, context);
end
