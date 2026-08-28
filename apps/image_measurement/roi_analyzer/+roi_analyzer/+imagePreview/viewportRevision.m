function revision = viewportRevision(sourceId, imageData)
%VIEWPORTREVISION Refit only when source identity or canvas size changes.
if isempty(imageData)
    revision = "source:none";
else
    revision = "source:" + string(sourceId) + ":" + ...
        join(string(size(imageData, 1:2)), "x");
end
end
