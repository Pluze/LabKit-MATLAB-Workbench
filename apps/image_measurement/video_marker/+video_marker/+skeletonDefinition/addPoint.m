%ADDPOINT Append one uniquely named keypoint to a skeleton definition.
% Expected caller: visual skeleton configurator. Output preserves all edges.
function [skeleton, index] = addPoint(skeleton)
    index = numel(skeleton.pointNames) + 1;
    candidate = "point_" + index;
    while any(lower(skeleton.pointNames) == lower(candidate))
        index = index + 1;
        candidate = "point_" + index;
    end
    names = [skeleton.pointNames; candidate];
    skeleton = video_marker.skeletonDefinition.fromParts(names, skeleton.edges);
    index = numel(names);
end
