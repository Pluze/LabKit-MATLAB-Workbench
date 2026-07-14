%SETFRAMEPOINTS Store points, status, provenance, and optional confidence.
% Expected caller: point editor, automatic tracker, imports, and tests. Points
% are ordered rows. Source defaults to manual; confidence defaults to one for
% manual points and NaN otherwise.
function annotations = setFramePoints(annotations, frameIndex, points, statusName, sourceName, confidence, anchorRevision)
    annotations = video_marker.frameAnnotations.upgradeAnnotationSchema(annotations);
    if nargin < 5
        sourceName = "manual";
    end
    frameIndex = round(double(frameIndex));
    pointCount = size(annotations.coords, 2);
    points = double(points);
    if size(points, 2) ~= 2 || size(points, 1) > pointCount
        error('labkit_VideoMarker_app:InvalidPoints', 'Points must be K-by-2 with K no larger than the skeleton point count.');
    end
    if any(~isfinite(points(:)))
        error('labkit_VideoMarker_app:InvalidPoints', 'Placed points must be finite.');
    end
    if string(statusName) == "confirmed" && size(points, 1) ~= pointCount
        error('labkit_VideoMarker_app:IncompleteFrame', 'Confirmed frames must contain every keypoint.');
    end
    annotations.coords(frameIndex, :, :) = NaN;
    if ~isempty(points)
        annotations.coords(frameIndex, 1:size(points, 1), 1) = points(:, 1);
        annotations.coords(frameIndex, 1:size(points, 1), 2) = points(:, 2);
    end
    if isempty(points)
        statusName = "empty";
        sourceName = "empty";
    end
    annotations.frameStatus(frameIndex) = video_marker.frameAnnotations.statusCode(statusName);
    annotations.frameSource(frameIndex) = video_marker.frameAnnotations.sourceCode(sourceName);
    annotations.trackingConfidence(frameIndex, :) = NaN;
    if ~isempty(points)
        if nargin < 6
            if string(sourceName) == "manual"
                confidence = ones(size(points, 1), 1);
            else
                confidence = NaN(size(points, 1), 1);
            end
        end
        confidence = double(confidence(:));
        if isscalar(confidence)
            confidence = repmat(confidence, size(points, 1), 1);
        end
        if numel(confidence) ~= size(points, 1)
            error('labkit_VideoMarker_app:InvalidTrackingConfidence', ...
                'Tracking confidence must contain one value per point.');
        end
        annotations.trackingConfidence(frameIndex, 1:size(points, 1)) = confidence;
    end
    if string(sourceName) == "manual"
        if nargin < 7
            anchorRevision = max(annotations.anchorRevision, [], 'all') + 1;
        end
        annotations.anchorRevision(frameIndex) = uint64(anchorRevision);
    elseif string(sourceName) == "predicted"
        if nargin < 7
            anchorRevision = 0;
        end
        annotations.anchorRevision(frameIndex) = uint64(anchorRevision);
    else
        annotations.anchorRevision(frameIndex) = uint64(0);
    end
end
