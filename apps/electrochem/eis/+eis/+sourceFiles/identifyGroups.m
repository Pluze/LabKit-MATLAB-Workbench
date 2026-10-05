function [groups, rejected] = identifyGroups(items, sources, groups)
%IDENTIFYGROUPS Propose frequency-compatible groups from final -digits suffixes.
% Auto-grouping considers only unassigned files; exact prefixes are case-sensitive.
% Called from explicit setup/auto-group actions, using already decoded scans.
rejected = {};
if isempty(sources), return; end
ids = string({sources.id});
assigned = string([groups.sourceIds]);
paths = labkit.app.source.paths(sources);
prefixes = strings(1, numel(sources));
for k = 1:numel(sources)
    if ismember(ids(k), assigned), continue; end
    [~, stem] = fileparts(paths(k));
    tokens = regexp(stem, '^(.+)-[0-9]+$', 'tokens', 'once');
    if ~isempty(tokens), prefixes(k) = string(tokens{1}); end
end
names = unique(prefixes(strlength(prefixes) > 0), "stable");
placeholder = eis.workbench.groupChoices(struct("name", {}));
rejected = cell(1, numel(names));
for index = 1:numel(names)
    name = names(index);
    if name == placeholder(1), continue; end
    existing = find(string({groups.name}) == name, 1);
    if isempty(existing)
        selected = ids(prefixes == name);
    else
        selected = [groups(existing).sourceIds, ids(prefixes == name)];
    end
    [~, positions] = ismember(selected, ids);
    try
        eis.analysisRun.groupCoordinates(items(positions), "Zreal", "-Zimag", "Ω");
    catch exception
        if ~startsWith(string(exception.identifier), "eis:"), rethrow(exception); end
        rejected{index} = exception;
        continue
    end
    if isempty(existing)
        existing = numel(groups) + 1;
    end
    groups(existing) = struct("name", name, "sourceIds", selected);
end
rejected = rejected(~cellfun(@isempty, rejected));
end
