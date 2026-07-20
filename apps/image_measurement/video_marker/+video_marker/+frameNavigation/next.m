% App-owned implementation for video_marker.frameNavigation.next within the video_marker product workflow.
function state = next(state, context)
%NEXT Move to the next video frame.
state = video_marker.frameNavigation.changeFrame( ...
    state, state.session.cache.frameIndex + 1, context);
end
