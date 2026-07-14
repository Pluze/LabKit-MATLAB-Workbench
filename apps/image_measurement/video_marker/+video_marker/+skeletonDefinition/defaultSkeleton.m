%DEFAULTSKELETON Return an empty skeleton for user configuration.
% Expected caller: app state factory and reset actions. Side effects are none.
function skeleton = defaultSkeleton()
    skeleton = video_marker.skeletonDefinition.fromParts(strings(0, 1), zeros(0, 2));
end
