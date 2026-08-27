% Expected caller: RHS Preview presentation and direct tests. Source identity,
% channel family/selection, and decoded time window own the waveform domain.
% ROI overlay edits, roles, labels, filters, and status changes preserve zoom.
function revision = viewportRevision(sources, family, preview)
sourceIds = strings(1, 0);
if ~isempty(sources)
    rhsSources = sources(string({sources.role}) == "recording");
    sourceIds = reshape(string({rhsSources.id}), 1, []);
end
channels = strings(1, 0);
timeRange = [0 0];
if isstruct(preview) && isfield(preview, "channels")
    channels = reshape(string(preview.channels), 1, []);
end
if isstruct(preview) && isfield(preview, "timeSec") && ...
        ~isempty(preview.timeSec)
    time = double(preview.timeSec(:));
    timeRange = [time(1), time(end)];
end
revision = string(jsonencode(struct( ...
    "sourceIds", {sourceIds}, ...
    "family", string(family), ...
    "channels", {channels}, ...
    "timeRange", timeRange)));
end
