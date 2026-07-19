% App workflow registry; returns handlers for table, analysis, plot, and export.
function handlers = stateHandlers()
%STATEHANDLERS Return T-Test Wizard semantic state handlers.
%
% Expected caller: ttest_wizard.definition. Handlers own source loading,
% visible cell selection, editable ordered groups, first-group comparisons,
% result freshness, and CSV export. They do not access the UI registry.

    handlers = struct( ...
        "sheetChanged", labkit.app.StateHandler( ...
            "sheetChanged", @onSheetChanged, Event="valueChange"), ...
        "sourceSelectionChanged", labkit.app.StateHandler( ...
            "sourceSelectionChanged", @onSourceSelectionChanged, ...
            Event="tableCellSelection"), ...
        "analysisSelectionChanged", labkit.app.StateHandler( ...
            "analysisSelectionChanged", @onAnalysisSelectionChanged, ...
            Event="tableCellSelection"), ...
        "captureGroup", labkit.app.StateHandler( ...
            "captureGroup", @onCaptureGroup), ...
        "assignRowsToGroup", labkit.app.StateHandler( ...
            "assignRowsToGroup", @onAssignRowsToGroup), ...
        "deleteSelectedRows", labkit.app.StateHandler( ...
            "deleteSelectedRows", @onDeleteSelectedRows), ...
        "groupsEdited", labkit.app.StateHandler( ...
            "groupsEdited", @onGroupsEdited, Event="tableCellEdit"), ...
        "clearGroups", labkit.app.StateHandler( ...
            "clearGroups", @onClearGroups), ...
        "testSettingsChanged", labkit.app.StateHandler( ...
            "testSettingsChanged", @onTestSettingsChanged, ...
            Event="valueChange"), ...
        "runComparisons", labkit.app.StateHandler( ...
            "runComparisons", @onRunComparisons), ...
        "plotChanged", labkit.app.StateHandler( ...
            "plotChanged", @onPlotChanged, Event="valueChange"), ...
        "exportData", labkit.app.StateHandler( ...
            "exportData", @onExportData), ...
        "exportResult", labkit.app.StateHandler( ...
            "exportResult", @onExportResult));
end

function state = onSheetChanged(state, requested, context)
    arguments
        state (1, 1) struct
        requested
        context (1, 1) labkit.app.CallbackContext
    end
    source = state.session.cache.source;
    if ~source.ok || isempty(state.project.inputs.sources)
        return;
    end
    requested = string(requested);
    if ~isscalar(requested) || ~any(requested == source.sheetNames)
        requested = source.sheetNames(1);
    end
    paths = context.resolveSourcePaths(state.project.inputs.sources);
    filepath = paths(1);
    try
        source = ttest_wizard.sourceTable.readSourceTable( ...
            filepath, requested);
    catch ME
        context.reportError("Change worksheet", ME);
        context.alert(ME.message, "Worksheet");
        return;
    end
    state.project.inputs.sourceSheet = source.sheet;
    state.session.cache.source = source;
    state.session.selection.sourceCells = zeros(0, 2);
    state.session.selection.selectionMessage = ...
        "Select numeric cells in the new worksheet.";
    context.appendStatus("Worksheet: " + source.sheet);
end

function state = onSourceSelectionChanged(state, selection, context)
    arguments
        state (1, 1) struct
        selection (1, 1) labkit.app.event.TableCellSelection
        context (1, 1) labkit.app.CallbackContext
    end
    indices = selection.CellIndices;
    state.session.selection.sourceCells = double(indices);
    source = state.session.cache.source;
    if ~source.ok || isempty(indices)
        state.session.selection.selectionMessage = ...
            "Select numeric cells in the opened table.";
        return;
    end
    selection = ttest_wizard.sourceTable.extractNumericSelection( ...
        source.cells, indices);
    state.session.selection.selectionMessage = selection.message;
end

function state = onAnalysisSelectionChanged(state, selection, context)
    arguments
        state (1, 1) struct
        selection (1, 1) labkit.app.event.TableCellSelection
        context (1, 1) labkit.app.CallbackContext
    end
    indices = selection.CellIndices;
    state.session.selection.analysisCells = double(indices);
end

function state = onCaptureGroup(state, context)
    arguments
        state (1, 1) struct
        context (1, 1) labkit.app.CallbackContext
    end
    source = state.session.cache.source;
    indices = state.session.selection.sourceCells;
    if ~source.ok || isempty(indices)
        context.alert( ...
            "Select cells in the opened table first.", "Select data");
        return;
    end
    selection = ttest_wizard.sourceTable.extractNumericSelection( ...
        source.cells, indices);
    state.session.selection.selectionMessage = selection.message;
    if ~selection.ok
        context.alert(selection.message, ...
            "Selected cells cannot be used");
        return;
    end

    groups = state.project.inputs.groups;
    target = string(state.project.parameters.captureTarget);
    groupIndex = find(string({groups.label}) == target, 1);
    if isempty(groupIndex)
        label = ttest_wizard.sourceTable.suggestGroupLabel( ...
            source.cells, indices, [groups.label]);
        group = emptyGroup(label);
        group.sourceDisplayName = source.displayName;
        group.sheet = source.sheet;
        groups(end + 1, 1) = group;
        groupIndex = numel(groups);
    end
    groups(groupIndex).values = [ ...
        groups(groupIndex).values(:); selection.values(:)];
    groups(groupIndex).cellAddresses = [ ...
        groups(groupIndex).cellAddresses(:); selection.addresses(:)];
    state.project.inputs.groups = groups;
    state.project.parameters.captureTarget = "(new group)";
    state = dataChanged(state);
    context.appendStatus(sprintf( ...
        'Added %d value(s) to %s.', ...
        selection.acceptedCount, groups(groupIndex).label));
end

function state = onAssignRowsToGroup(state, context)
    arguments
        state (1, 1) struct
        context (1, 1) labkit.app.CallbackContext
    end
    target = string(state.session.selection.batchGroupTarget);
    selectedRows = selectedObservationRows(state);
    if target == "(select group)" || isempty(selectedRows)
        return;
    end
    groups = reassignObservationRows( ...
        state.project.inputs.groups, selectedRows, target);
    state.project.inputs.groups = groups;
    state.session.selection.analysisCells = zeros(0, 2);
    state = dataChanged(state);
    context.appendStatus(sprintf( ...
        'Changed %d selected row(s) to %s.', ...
        numel(selectedRows), target));
end

function state = onDeleteSelectedRows(state, context)
    arguments
        state (1, 1) struct
        context (1, 1) labkit.app.CallbackContext
    end
    selectedRows = selectedObservationRows(state);
    if isempty(selectedRows)
        return;
    end
    state.project.inputs.groups = deleteObservationRows( ...
        state.project.inputs.groups, selectedRows);
    state.session.selection.analysisCells = zeros(0, 2);
    remainingLabels = string({state.project.inputs.groups.label});
    if ~any(remainingLabels == string( ...
            state.project.parameters.captureTarget))
        state.project.parameters.captureTarget = "(new group)";
    end
    if ~any(remainingLabels == string( ...
            state.session.selection.batchGroupTarget))
        state.session.selection.batchGroupTarget = "(select group)";
    end
    state = dataChanged(state);
    context.appendStatus(sprintf( ...
        'Deleted %d selected row(s).', numel(selectedRows)));
end

function state = onGroupsEdited(state, edit, context)
    arguments
        state (1, 1) struct
        edit (1, 1) labkit.app.event.TableCellEdit
        context (1, 1) labkit.app.CallbackContext
    end
    data = edit.Data;
    if ~iscell(data) || size(data, 2) < 2
        context.alert( ...
            "The data table must contain Group and Value columns.", ...
            "Edit analysis data");
        return;
    end
    [groups, ok, message] = groupsFromRows( ...
        data(:, 1), data(:, 2), state.project.inputs.groups);
    if ~ok
        context.alert(message, "Edit analysis data");
        return;
    end
    state.project.inputs.groups = groups;
    if ~any([groups.label] == string( ...
            state.project.parameters.captureTarget))
        state.project.parameters.captureTarget = "(new group)";
    end
    state = dataChanged(state);
    context.appendStatus(sprintf( ...
        'Updated analysis data: %d group(s), %d value(s).', ...
        numel(groups), sum(arrayfun( ...
        @(group) numel(group.values), groups))));
end

function state = onClearGroups(state, context)
    arguments
        state (1, 1) struct
        context (1, 1) labkit.app.CallbackContext
    end
    state.project.inputs.groups = repmat(emptyGroup("Group 1"), 0, 1);
    state.project.parameters.captureTarget = "(new group)";
    state.session.selection.analysisCells = zeros(0, 2);
    state.session.selection.batchGroupTarget = "(select group)";
    state = dataChanged(state);
    context.appendStatus("Cleared all analysis data.");
end

function state = dataChanged(state)
    state.project.results.lastDataExport = "";
end

function state = onTestSettingsChanged(state, newValue, context)
    arguments
        state (1, 1) struct
        newValue
        context (1, 1) labkit.app.CallbackContext
    end
    alpha = double(state.project.parameters.alpha);
    if ~isscalar(alpha) || ~isfinite(alpha) || alpha <= 0 || alpha >= 1
        state.project.parameters.alpha = 0.05;
        context.alert( ...
            "Alpha must be between zero and one. It was reset to 0.05.", ...
            "Test settings");
    end
end

function state = onRunComparisons(state, context)
    arguments
        state (1, 1) struct
        context (1, 1) labkit.app.CallbackContext
    end
    groups = state.project.inputs.groups;
    if numel(groups) < 2
        context.alert( ...
            "Enter at least two groups before running comparisons.", ...
            "T-tests");
        return;
    end
    results = ttest_wizard.testRun.runGroupTTests( ...
        groups, currentTestOptions(state));
    state.project.results.current = results;
    state.project.results.lastResultExport = "";
    okCount = sum([results.ok]);
    context.appendStatus(sprintf( ...
        'Completed %d of %d comparison(s) against %s.', ...
        okCount, numel(results), groups(1).label));
    if okCount < numel(results)
        failed = results(~[results.ok]);
        context.alert(strjoin(unique([failed.message]), newline), ...
            "Some t-tests were not completed");
    end
end

function state = onPlotChanged(state, newValue, context)
    arguments
        state (1, 1) struct
        newValue
        context (1, 1) labkit.app.CallbackContext
    end
    % Plot-only settings intentionally do not change the result family.
end

function state = onExportData(state, context)
    arguments
        state (1, 1) struct
        context (1, 1) labkit.app.CallbackContext
    end
    groups = state.project.inputs.groups;
    if isempty(groups)
        context.alert( ...
            "Enter group data before exporting.", "Export data");
        return;
    end
    chosen = context.chooseOutputFile( ...
        ["*.csv", "CSV table (*.csv)"], ...
        fullfile(pwd, "ttest_group_data.csv"));
    if chosen.Cancelled
        return;
    end
    filepath = string(chosen.Value);
    filepath = ensureCsvExtension(filepath);
    try
        ttest_wizard.sourceTable.writeGroupCsv(filepath, groups);
    catch ME
        context.reportError("Export group data", ME);
        context.alert(ME.message, "Export data");
        return;
    end
    state.project.results.lastDataExport = string(filepath);
    context.appendStatus("Exported group data: " + string(filepath));
end

function state = onExportResult(state, context)
    arguments
        state (1, 1) struct
        context (1, 1) labkit.app.CallbackContext
    end
    results = state.project.results.current;
    if isempty(results)
        context.alert( ...
            "Run comparisons before exporting results.", "Export results");
        return;
    end
    chosen = context.chooseOutputFile( ...
        ["*.csv", "CSV table (*.csv)"], ...
        fullfile(pwd, "ttest_results.csv"));
    if chosen.Cancelled
        return;
    end
    filepath = string(chosen.Value);
    filepath = ensureCsvExtension(filepath);
    try
        ttest_wizard.resultFiles.writeResultCsv(filepath, results);
    catch ME
        context.reportError("Export t-test results", ME);
        context.alert(ME.message, "Export results");
        return;
    end
    state.project.results.lastResultExport = string(filepath);
    context.appendStatus("Exported t-test results: " + string(filepath));
end

function [groups, ok, message] = groupsFromRows( ...
        labels, values, priorGroups)
    groups = repmat(emptyGroup("Group 1"), 0, 1);
    ok = true;
    message = "";
    priorLabel = "";
    for row = 1:numel(values)
        label = strip(string(labels{row}));
        value = values{row};
        if isBlankValue(value) && strlength(label) == 0
            continue;
        end
        if strlength(label) == 0
            label = priorLabel;
        end
        if strlength(label) == 0
            ok = false;
            message = sprintf( ...
                'Row %d needs a group name before its value.', row);
            return;
        end
        [number, valid] = finiteScalar(value);
        if ~valid
            ok = false;
            message = sprintf( ...
                'Row %d Value must be one finite number.', row);
            return;
        end
        groupIndex = find(strcmpi(label, [groups.label]), 1);
        if isempty(groupIndex)
            group = emptyGroup(label);
            priorIndex = find(strcmpi(label, [priorGroups.label]), 1);
            if ~isempty(priorIndex)
                group = priorGroups(priorIndex);
                group.values = zeros(0, 1);
                group.cellAddresses = strings(0, 1);
            else
                group.sourceDisplayName = "Manual data table";
            end
            groups(end + 1, 1) = group;
            groupIndex = numel(groups);
        end
        groups(groupIndex).values(end + 1, 1) = number;
        priorLabel = groups(groupIndex).label;
    end
end

function groups = reassignObservationRows(groups, selectedRows, target)
    visibleRows = cell(numel(groups), 1);
    movedValueParts = repmat({zeros(0, 1)}, numel(groups), 1);
    movedAddressParts = repmat({strings(0, 1)}, numel(groups), 1);
    rowOffset = 0;
    for groupIndex = 1:numel(groups)
        count = numel(groups(groupIndex).values);
        visibleRows{groupIndex} = rowOffset + (1:count);
        rowOffset = rowOffset + count;
        move = ismember(visibleRows{groupIndex}, selectedRows);
        if groups(groupIndex).label ~= target
            movedValueParts{groupIndex} = groups(groupIndex).values(move);
            addresses = string(groups(groupIndex).cellAddresses(:));
            if numel(addresses) == count
                movedAddressParts{groupIndex} = addresses(move);
                groups(groupIndex).cellAddresses = addresses(~move);
            end
            groups(groupIndex).values = groups(groupIndex).values(~move);
        end
    end
    movedValues = vertcat(movedValueParts{:});
    movedAddresses = vertcat(movedAddressParts{:});
    targetIndex = find([groups.label] == target, 1);
    groups(targetIndex).values = [ ...
        groups(targetIndex).values(:); movedValues];
    groups(targetIndex).cellAddresses = [ ...
        string(groups(targetIndex).cellAddresses(:)); movedAddresses];
    groups = groups(arrayfun(@(group) ~isempty(group.values), groups));
end

function groups = deleteObservationRows(groups, selectedRows)
    rowOffset = 0;
    for groupIndex = 1:numel(groups)
        count = numel(groups(groupIndex).values);
        visibleRows = rowOffset + (1:count);
        rowOffset = rowOffset + count;
        remove = ismember(visibleRows, selectedRows);
        groups(groupIndex).values = groups(groupIndex).values(~remove);
        addresses = string(groups(groupIndex).cellAddresses(:));
        if numel(addresses) == count
            groups(groupIndex).cellAddresses = addresses(~remove);
        else
            groups(groupIndex).cellAddresses = strings(0, 1);
        end
    end
    groups = groups(arrayfun(@(group) ~isempty(group.values), groups));
end

function rows = selectedObservationRows(state)
    rows = unique(state.session.selection.analysisCells(:, 1), 'stable');
    observationCount = sum(arrayfun( ...
        @(group) numel(group.values), state.project.inputs.groups));
    rows = rows(rows >= 1 & rows <= observationCount);
end

function tf = isBlankValue(value)
    tf = isempty(value) || ...
        ((ischar(value) || (isstring(value) && isscalar(value))) && ...
        strlength(strip(string(value))) == 0);
end

function [number, valid] = finiteScalar(value)
    if (isnumeric(value) || islogical(value)) && isscalar(value)
        number = double(value);
    elseif ischar(value) || (isstring(value) && isscalar(value))
        number = str2double(strip(string(value)));
    else
        number = NaN;
    end
    valid = isfinite(number);
end

function value = emptyGroup(label)
    value = struct( ...
        "label", string(label), ...
        "values", zeros(0, 1), ...
        "sourceDisplayName", "", ...
        "sheet", "", ...
        "cellAddresses", strings(0, 1));
end

function options = currentTestOptions(state)
    options = struct( ...
        "method", state.project.parameters.testMethod, ...
        "alternative", state.project.parameters.alternative, ...
        "alpha", state.project.parameters.alpha);
end

function filepath = ensureCsvExtension(filepath)
    filepath = string(filepath);
    [folder, name, extension] = fileparts(filepath);
    if strlength(string(extension)) == 0
        filepath = string(fullfile(folder, name + ".csv"));
    end
end
