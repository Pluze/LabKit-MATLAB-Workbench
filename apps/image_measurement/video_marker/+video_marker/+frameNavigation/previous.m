function state = previous(state, context)
%PREVIOUS Move to the preceding video frame.
state = video_marker.frameNavigation.changeFrame( ...
    state, state.session.cache.frameIndex - 1, context);
end
