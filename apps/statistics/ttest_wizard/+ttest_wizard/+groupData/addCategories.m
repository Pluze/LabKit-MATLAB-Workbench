function applicationState = addCategories(applicationState, callbackContext)
%ADDCATEGORIES Add named empty destinations for later source or row assignment.
groups = applicationState.project.inputs.groups;
names = strip(split(string(applicationState.project.parameters.categoryNames), "|"));
allNames = [string({groups.label}).'; names];
if any(ismissing(names) | strlength(names) == 0) || ...
        numel(unique(lower(allNames))) ~= numel(allNames)
    callbackContext.alert("New category names must be nonempty and unique (case insensitive).", ...
        "Add categories");
    return;
end
added = repmat(ttest_wizard.groupData.emptyGroup(""), numel(names), 1);
for k = 1:numel(names)
    added(k).label = names(k);
end
groups = [groups(:); added];
applicationState.project.inputs.groups = groups;
applicationState.project.results.lastDataExport = "";
end
