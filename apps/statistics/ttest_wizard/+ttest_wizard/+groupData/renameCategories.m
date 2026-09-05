function applicationState = renameCategories(applicationState, callbackContext)
%RENAMECATEGORIES Apply the batch name list to the displayed categories atomically.
groups = applicationState.project.inputs.groups;
parameters = applicationState.project.parameters;
names = split(string(parameters.categoryNames), "|");
try
    [updated, parameters] = ttest_wizard.groupData.renameGroups(groups, parameters, names);
catch cause
    callbackContext.log("warning", "ttest_wizard.category_edit_rejected", ...
        "Category edit was rejected.", Exception=cause);
    callbackContext.alert(cause.message, "Rename categories");
    return;
end
[found, index] = ismember(applicationState.session.selection.batchGroupTarget, string({groups.label}));
if found, applicationState.session.selection.batchGroupTarget = updated(index).label; end
applicationState.project.inputs.groups = updated;
applicationState.project.parameters = parameters;
applicationState.project.results.lastDataExport = "";
end
