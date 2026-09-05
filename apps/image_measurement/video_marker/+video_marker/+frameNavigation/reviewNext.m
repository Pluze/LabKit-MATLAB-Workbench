function applicationState = reviewNext(applicationState, callbackContext)
%REVIEWNEXT Locate a matching frame without predicting or changing marks.
frames = applicationState.project.annotations.frames;
view = applicationState.session.view;
current = applicationState.session.cache.frameIndex;
indices = video_marker.frameNavigation.reviewFrames(frames, view.reviewMode, view.reviewThreshold);
match = find(indices > current, 1, "first");
if isempty(match), return; end
applicationState = video_marker.frameNavigation.changeFrame( ...
    applicationState, indices(match), callbackContext);
end
