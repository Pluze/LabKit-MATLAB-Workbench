% App-owned implementation for video_marker.frameNavigation.previous within the video_marker product workflow.
function state = previous(state, context)
%PREVIOUS Move to the preceding video frame.
state = video_marker.frameNavigation.changeFrame( ...
    state, state.session.cache.frameIndex - 1, context);
end
