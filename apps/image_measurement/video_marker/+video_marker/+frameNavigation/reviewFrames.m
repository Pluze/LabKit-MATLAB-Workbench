function indices = reviewFrames(annotations, mode, threshold)
%REVIEWFRAMES Select frame indices from saved status/provenance/confidence.
% Called by review navigation and presentation. Confidence is an algorithmic
% score, not probability. Unknown predicted confidence always needs review.
if ~isnumeric(threshold) || ~isreal(threshold) || ~isscalar(threshold) || ~isfinite(threshold) || threshold < 0 || threshold > 1
    error("video_marker:InvalidReviewThreshold", "Review threshold must be between zero and one.");
end
switch string(mode)
    case "Unreviewed"
        mask = annotations.frameStatus ~= video_marker.frameAnnotations.statusCode("confirmed");
    case "Unmarked"
        mask = annotations.frameStatus == video_marker.frameAnnotations.statusCode("empty");
    case "Predicted"
        mask = annotations.frameSource == video_marker.frameAnnotations.sourceCode("predicted");
    case "Low/unknown confidence"
        scores = annotations.trackingConfidence;
        mask = annotations.frameSource == video_marker.frameAnnotations.sourceCode("predicted") & ...
            any(~isfinite(scores) | scores < threshold, 2);
    otherwise
        error("video_marker:InvalidReviewMode", "Unknown annotation review filter.");
end
indices = find(mask(:));
end
