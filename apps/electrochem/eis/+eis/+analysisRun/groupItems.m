function grouped = groupItems(items, sources, groups)
%GROUPITEMS Resolve App-owned source IDs to current decoded repetitions.
% Used by presentation and export; never pairs by file-list position alone.
grouped = repmat(struct("name", "", "members", struct([])), 1, numel(groups));
keep = false(1, numel(groups));
if isempty(sources)
    grouped = grouped(keep);
    return
end
ids = string({sources.id});
for k = 1:numel(groups)
    [found, indices] = ismember(groups(k).sourceIds, ids);
    if any(found)
        keep(k) = true;
        grouped(k) = struct("name", groups(k).name, ...
            "members", items(indices(found)));
    end
end
grouped = grouped(keep);
end
