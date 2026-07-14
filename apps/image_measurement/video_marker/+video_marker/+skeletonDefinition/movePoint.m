%MOVEPOINT Move one keypoint by one ordered position and remap connections.
% Expected caller: visual skeleton configurator before a video is opened.
function [skeleton, newIndex] = movePoint(skeleton, index, delta)
    newIndex = min(max(1, index + sign(delta)), numel(skeleton.pointNames));
    if newIndex == index
        return;
    end
    order = 1:numel(skeleton.pointNames);
    order([index newIndex]) = order([newIndex index]);
    inverse(order) = 1:numel(order);
    skeleton = video_marker.skeletonDefinition.fromParts( ...
        skeleton.pointNames(order), inverse(skeleton.edges));
end
