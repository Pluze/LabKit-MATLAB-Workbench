%CONNECTINORDER Add every adjacent ordered-keypoint connection.
% Expected caller: the visual skeleton configurator. Existing connections are
% preserved; duplicate undirected edges are normalized by fromParts.
function skeleton = connectInOrder(skeleton)
    pointCount = numel(skeleton.pointNames);
    if pointCount < 2
        return;
    end
    sequentialEdges = [(1:pointCount - 1).' (2:pointCount).'];
    skeleton = video_marker.skeletonDefinition.fromParts( ...
        skeleton.pointNames, [skeleton.edges; sequentialEdges]);
end
