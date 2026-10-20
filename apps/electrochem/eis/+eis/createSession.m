function session = createSession(project, ~)
%CREATESESSION Rebuild EIS overlay curves from source-list paths.
paths = labkit.app.source.paths(project.inputs.sources);
items = eis.sourceFiles.loadProjectItems(paths);
frequencyBounds = [Inf -Inf];
for k = 1:numel(items)
    frequency = items(k).freq_Hz(:);
    frequency = frequency(isfinite(frequency) & frequency > 0);
    if ~isempty(frequency)
        frequencyBounds = [min(frequencyBounds(1), min(frequency)), ...
            max(frequencyBounds(2), max(frequency))];
    end
end
available = all(isfinite(frequencyBounds));
limits = [0 1];
if available
    limits = log10(frequencyBounds);
    if limits(1) == limits(2), limits = limits + [-.5 .5]; end
end
[recommended, supported] = eis.overlayPlot.recommendFrequency(items, limits(1));
nyquist = struct("limits", limits, "lower", recommended, ...
    "recommended", recommended, "supported", supported, ...
    "upper", limits(2), "available", available);
selection = labkit.app.event.ListSelection(Indices=1:numel(paths));
session = struct("nyquist", nyquist, "selection", struct("files", selection), ...
    "cache", struct("items", items, "plotViewRevision", 0, ...
    "plotViewAction", "", "overviewViewRevision", 0));
end
