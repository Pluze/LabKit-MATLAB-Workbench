%METADATAFROMINFO Select durable numeric facts from opened-video metadata.
% Expected caller: video open/import actions. Input may contain transient path
% data; output contains finite serializable scalars only.
function metadata = metadataFromInfo(info)
    metadata = video_marker.videoSource.emptyMetadata();
    names = string(fieldnames(metadata));
    for k = 1:numel(names)
        name = char(names(k));
        if ~isstruct(info) || ~isfield(info, name)
            continue;
        end
        value = double(info.(name));
        if isscalar(value) && isfinite(value) && value >= 0
            metadata.(name) = value;
        end
    end
end
