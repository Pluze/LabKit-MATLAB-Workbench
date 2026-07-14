%RENAMEPOINT Rename one ordered keypoint without changing its connections.
% Expected caller: visual skeleton configurator. Index is 1-based.
function skeleton = renamePoint(skeleton, index, name)
    names = skeleton.pointNames;
    names(index) = string(name);
    skeleton = video_marker.skeletonDefinition.fromParts(names, skeleton.edges);
end
