function state = invalidate(state, sourceId)
%INVALIDATE Mark measurements stale after ROI geometry or identity changes.
items = state.project.results.items;
match = find(string({items.sourceId}) == string(sourceId), 1);
if ~isempty(match)
    items(match).roiFingerprint = "";
    items(match).summary = table();
    items(match).metrics = table();
end
state.project.results.items = items;
state.project.results.lastExportPath = "";
end
