%DEFAULTSKELETON Return the generic starter keypoint chain.
% Expected caller: app state factory and reset actions. Side effects are none.
function skeleton = defaultSkeleton()
    skeleton = video_marker.skeletonDefinition.fromText( ...
        "point_1, point_2, point_3, point_4, point_5", ...
        "point_1-point_2, point_2-point_3, point_3-point_4, point_4-point_5");
end
