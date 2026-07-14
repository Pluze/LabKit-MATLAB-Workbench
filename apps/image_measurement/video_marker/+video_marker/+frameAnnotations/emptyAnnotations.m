%EMPTYANNOTATIONS Allocate annotation arrays for F frames and P keypoints.
% Expected caller: video open, skeleton reset, imports, and tests.
function annotations = emptyAnnotations(frameCount, pointCount)
    frameCount = max(0, round(double(frameCount)));
    pointCount = max(0, round(double(pointCount)));
    annotations = struct();
    annotations.schemaVersion = 2;
    annotations.coords = NaN(frameCount, pointCount, 2);
    annotations.frameStatus = zeros(frameCount, 1, 'uint8');
    annotations.frameSource = zeros(frameCount, 1, 'uint8');
    annotations.trackingConfidence = NaN(frameCount, pointCount);
    annotations.anchorRevision = zeros(frameCount, 1, 'uint64');
end
