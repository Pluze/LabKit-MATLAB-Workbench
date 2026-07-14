%ADDEDGE Add a unique connection between two keypoint indices.
% Expected caller: visual skeleton configurator.
function skeleton = addEdge(skeleton, firstIndex, secondIndex)
    skeleton = video_marker.skeletonDefinition.fromParts( ...
        skeleton.pointNames, [skeleton.edges; firstIndex secondIndex]);
end
