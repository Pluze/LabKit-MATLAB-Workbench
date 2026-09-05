function applicationState = editCategories(applicationState, edit, callbackContext)
%EDITCATEGORIES Commit a category rename, position change, or comparison flag.
% Native table callback; values stay in their category and paired order is intact.
groups = applicationState.project.inputs.groups;
parameters = applicationState.project.parameters;
row = edit.RowIndex;
if row < 1 || row > numel(groups), return; end
try
    switch edit.ColumnIndex
        case 1
            names = string({groups.label});
            names(row) = string(edit.NewValue);
            old = groups(row).label;
            [groups, parameters] = ttest_wizard.groupData.renameGroups(groups, parameters, names);
            if applicationState.session.selection.batchGroupTarget == old
                applicationState.session.selection.batchGroupTarget = groups(row).label;
            end
        case 2
            position = str2double(string(edit.NewValue));
            if ~isscalar(position) || ~isfinite(position) || position ~= fix(position) || ...
                    position < 1 || position > numel(groups)
                error("ttest_wizard:groupData:InvalidPosition", ...
                    "Position must be an integer from 1 to the number of categories.");
            end
            if strlength(parameters.referenceGroup) == 0
                parameters.referenceGroup = groups(1).label;
            end
            indices = 1:numel(groups);
            indices(row) = [];
            indices = [indices(1:position-1), row, indices(position:end)];
            groups = groups(indices);
            applicationState.session.cache.plotViewRevision = ...
                applicationState.session.cache.plotViewRevision + 1;
        case 3
            enabled = edit.NewValue;
            if ~isscalar(enabled) || ~islogical(enabled)
                error("ttest_wizard:groupData:InvalidSelection", "Compare must be a checkbox value.");
            end
            excluded = parameters.excludedComparisonGroups;
            excluded(excluded == groups(row).label) = [];
            if ~enabled, excluded(end + 1) = groups(row).label; end
            parameters.excludedComparisonGroups = excluded;
        otherwise
            return;
    end
catch cause
    callbackContext.log("warning", "ttest_wizard.category_edit_rejected", ...
        "Category edit was rejected.", Exception=cause);
    callbackContext.alert(cause.message, "Edit categories");
    return;
end
applicationState.project.inputs.groups = groups;
applicationState.project.parameters = parameters;
applicationState.session.selection.analysisCells = zeros(0, 2);
applicationState.project.results.lastDataExport = "";
end
