%SUMMARY Build a compact annotation completeness summary.
% Expected caller: UI refresh and tests.
function info = summary(annotations)
    statuses = annotations.frameStatus(:);
    info = struct();
    info.frameCount = numel(statuses);
    info.empty = sum(statuses == video_marker.frameAnnotations.statusCode("empty"));
    info.draft = sum(statuses == video_marker.frameAnnotations.statusCode("draft"));
    info.confirmed = sum(statuses == video_marker.frameAnnotations.statusCode("confirmed"));
end
