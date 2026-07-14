%PREDICTFORWARD Propagate points through later frames until the target frame.
% Expected caller: Video Marker forward navigation. Manual frames are immutable
% anchors; empty or previously predicted frames are replaced by fresh KLT
% predictions. Returns the target image and a compact diagnostic report.
function [annotations, targetImage, report] = predictForward( ...
        readFrameFcn, annotations, startFrame, targetFrame, startImage)
    annotations = video_marker.frameAnnotations.upgradeAnnotationSchema(annotations);
    startFrame = round(double(startFrame));
    targetFrame = round(double(targetFrame));
    if targetFrame <= startFrame
        error('labkit_VideoMarker_app:InvalidPredictionRange', ...
            'Forward prediction requires a later target frame.');
    end
    points = video_marker.frameAnnotations.framePoints(annotations, startFrame);
    pointCount = size(annotations.coords, 2);
    if size(points, 1) ~= pointCount
        error('labkit_VideoMarker_app:IncompleteTrackingAnchor', ...
            'Forward prediction requires a complete current frame.');
    end
    prior = previousDisplacement(annotations, startFrame, points);
    previousImage = startImage;
    previousImageFrame = startFrame;
    report = struct('predictedFrames', 0, 'manualAnchors', 0, ...
        'cachedFrames', 0, 'fallbackPoints', 0, ...
        'minimumConfidence', 1, 'engine', "pyramidal_klt");
    targetImage = [];
    manualCode = video_marker.frameAnnotations.sourceCode("manual");
    predictedCode = video_marker.frameAnnotations.sourceCode("predicted");
    anchorRevision = annotations.anchorRevision(startFrame);
    for frameIndex = startFrame + 1:targetFrame
        existing = video_marker.frameAnnotations.framePoints(annotations, frameIndex);
        isManualAnchor = annotations.frameSource(frameIndex) == manualCode && ...
            size(existing, 1) == pointCount;
        previousPoints = points;
        if isManualAnchor
            points = existing;
            prior = points - previousPoints;
            anchorRevision = annotations.anchorRevision(frameIndex);
            report.manualAnchors = report.manualAnchors + 1;
        elseif annotations.frameSource(frameIndex) == predictedCode && ...
                annotations.anchorRevision(frameIndex) == anchorRevision && ...
                size(existing, 1) == pointCount
            points = existing;
            prior = points - previousPoints;
            report.cachedFrames = report.cachedFrames + 1;
        else
            if previousImageFrame ~= frameIndex - 1
                previousImage = readFrameFcn(frameIndex - 1);
            end
            currentImage = readFrameFcn(frameIndex);
            [points, confidence, diagnostics] = ...
                video_marker.motionEstimate.trackPoints( ...
                previousImage, currentImage, previousPoints, prior);
            annotations = video_marker.frameAnnotations.setFramePoints( ...
                annotations, frameIndex, points, "draft", "predicted", ...
                confidence, anchorRevision);
            prior = points - previousPoints;
            report.predictedFrames = report.predictedFrames + 1;
            report.fallbackPoints = report.fallbackPoints + sum(~diagnostics.valid);
            report.minimumConfidence = min(report.minimumConfidence, min(confidence));
            report.engine = diagnostics.engine;
            previousImage = currentImage;
            previousImageFrame = frameIndex;
        end
        if frameIndex == targetFrame
            if exist('currentImage', 'var') ~= 1 || previousImageFrame ~= frameIndex
                currentImage = readFrameFcn(frameIndex);
            end
            targetImage = currentImage;
        end
    end
end

function displacement = previousDisplacement(annotations, frameIndex, points)
    displacement = zeros(size(points));
    if frameIndex <= 1
        return;
    end
    previous = video_marker.frameAnnotations.framePoints(annotations, frameIndex - 1);
    if isequal(size(previous), size(points))
        displacement = points - previous;
    end
end
