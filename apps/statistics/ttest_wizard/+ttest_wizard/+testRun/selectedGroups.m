function selected = selectedGroups(groups, parameters)
%SELECTEDGROUPS Resolve an explicit reference and enabled comparisons.
% Called by the Run callback and presenter; no statistical calculation occurs.
% Empty reference means the first category; an absent explicit reference fails closed.
selected = groups([]);
if isempty(groups), return; end
labels = string({groups.label});
reference = string(parameters.referenceGroup);
if strlength(reference) == 0, reference = labels(1); end
index = find(labels == reference, 1);
if isempty(index), return; end
comparisons = find(labels ~= reference & ~ismember(labels, parameters.excludedComparisonGroups));
selected = groups([index comparisons]);
end
