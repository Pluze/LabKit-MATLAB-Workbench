function [groups, parameters] = renameGroups(groups, parameters, names)
%RENAMEGROUPS Atomically rename categories without touching values or provenance.
% Called by category callbacks. Names are trimmed, unique ignoring case, and
% complete in current group order; reference and assignment labels follow them.
names = strip(string(names(:)));
if numel(names) ~= numel(groups) || any(ismissing(names) | strlength(names) == 0) || ...
        numel(unique(lower(names))) ~= numel(names)
    error("ttest_wizard:groupData:InvalidNames", ...
        "Provide one nonempty, unique name per category (case insensitive).");
end
old = string({groups.label});
for field = ["referenceGroup", "captureTarget", "excludedComparisonGroups"]
    values = parameters.(field);
    [found, index] = ismember(values, old);
    values(found) = names(index(found));
    parameters.(field) = values;
end
for k = 1:numel(groups), groups(k).label = names(k); end
end
