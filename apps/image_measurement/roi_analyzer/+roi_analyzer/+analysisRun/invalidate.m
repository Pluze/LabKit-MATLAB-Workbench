function results = invalidate(results, sourceId)
%INVALIDATE Mark measurements stale after ROI geometry or identity changes.
items = results.items;
match = find(string({items.sourceId}) == string(sourceId), 1);
if ~isempty(match)
    items(match).roiFingerprint = "";
    items(match).summary = table();
    items(match).metrics = table();
end
results.items = items;
results.lastExportPath = "";
if isfield(results, "batchStatus") && ~isempty(results.batchStatus)
    results.batchStatus(results.batchStatus.SourceId == string(sourceId), :) = [];
end
end
