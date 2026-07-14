%REMOVEPOINT Remove one keypoint and all incident connections.
% Expected caller: visual skeleton configurator. Remaining edge indices are remapped.
function skeleton = removePoint(skeleton, index)
    names = skeleton.pointNames;
    edges = skeleton.edges;
    names(index) = [];
    edges(any(edges == index, 2), :) = [];
    edges(edges > index) = edges(edges > index) - 1;
    skeleton = video_marker.skeletonDefinition.fromParts(names, edges);
end
