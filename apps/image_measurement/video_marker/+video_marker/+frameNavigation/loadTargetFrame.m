%LOADTARGETFRAME Load a navigation target and predict points when eligible.
% Expected caller: Video Marker frame navigation. Forward moves from a
% complete anchor invoke automatic prediction; backward or incomplete-anchor
% moves only read the requested image. No UI state or handles are mutated.
function [annotations, frame, report] = loadTargetFrame( ...
        readFrameFcn, annotations, startFrame, targetFrame, startImage, pointCount)
    startPoints = video_marker.frameAnnotations.framePoints(annotations, startFrame);
    canPredict = targetFrame > startFrame && size(startPoints, 1) == pointCount;
    if canPredict
        [annotations, frame, report] = ...
            video_marker.motionEstimate.predictForward( ...
            readFrameFcn, annotations, startFrame, targetFrame, startImage);
        return;
    end
    frame = readFrameFcn(targetFrame);
    report = struct('predictedFrames', 0, 'manualAnchors', 0, ...
        'cachedFrames', 0, 'fallbackPoints', 0, ...
        'minimumConfidence', 1, 'engine', "none");
end
