%REMOVEEDGE Remove one connection by its displayed row index.
% Expected caller: visual skeleton configurator.
function skeleton = removeEdge(skeleton, index)
    edges = skeleton.edges;
    edges(index, :) = [];
    skeleton = video_marker.skeletonDefinition.fromParts(skeleton.pointNames, edges);
end
