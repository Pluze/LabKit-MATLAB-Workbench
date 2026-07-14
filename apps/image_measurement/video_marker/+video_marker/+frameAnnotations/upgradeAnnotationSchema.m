%UPGRADEANNOTATIONSCHEMA Upgrade annotations to the current app schema.
% Expected callers are project loading and annotation mutators. Existing
% coordinates/status values are preserved; legacy complete frames become
% manual anchors and legacy drafts become predicted frames.
function annotations = upgradeAnnotationSchema(annotations)
    frameCount = size(annotations.coords, 1);
    pointCount = size(annotations.coords, 2);
    if ~isfield(annotations, 'frameSource') || numel(annotations.frameSource) ~= frameCount
        annotations.frameSource = zeros(frameCount, 1, 'uint8');
        confirmed = video_marker.frameAnnotations.statusCode("confirmed");
        draft = video_marker.frameAnnotations.statusCode("draft");
        annotations.frameSource(annotations.frameStatus == confirmed) = ...
            video_marker.frameAnnotations.sourceCode("manual");
        annotations.frameSource(annotations.frameStatus == draft) = ...
            video_marker.frameAnnotations.sourceCode("predicted");
    end
    if ~isfield(annotations, 'trackingConfidence') || ...
            ~isequal(size(annotations.trackingConfidence), [frameCount pointCount])
        annotations.trackingConfidence = NaN(frameCount, pointCount);
        manual = annotations.frameSource == ...
            video_marker.frameAnnotations.sourceCode("manual");
        annotations.trackingConfidence(manual, :) = 1;
    end
    if ~isfield(annotations, 'anchorRevision') || ...
            numel(annotations.anchorRevision) ~= frameCount
        annotations.anchorRevision = zeros(frameCount, 1, 'uint64');
        manualFrames = find(annotations.frameSource == ...
            video_marker.frameAnnotations.sourceCode("manual"));
        annotations.anchorRevision(manualFrames) = uint64(1:numel(manualFrames));
    end
    annotations.schemaVersion = 2;
end
