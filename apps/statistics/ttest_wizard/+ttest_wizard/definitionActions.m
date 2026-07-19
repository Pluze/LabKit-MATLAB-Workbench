% App workflow registry; returns handlers for table, analysis, plot, and export.
function actions = definitionActions()
%DEFINITIONACTIONS Return T-Test Wizard semantic workflow handlers.
%
% Expected caller: ttest_wizard.definition. Handlers own source loading,
% visible cell selection, editable ordered groups, first-group comparisons,
% result freshness, and CSV export. They do not access the UI registry.

    actions = struct( ...
        "openSource", @onOpenSource, ...
        "clearSource", @onClearSource, ...
        "sheetChanged", @onSheetChanged, ...
        "sourceSelectionChanged", @onSourceSelectionChanged, ...
        "analysisSelectionChanged", @onAnalysisSelectionChanged, ...
        "captureGroup", @onCaptureGroup, ...
        "assignRowsToGroup", @onAssignRowsToGroup, ...
        "deleteSelectedRows", @onDeleteSelectedRows, ...
        "groupsEdited", @onGroupsEdited, ...
        "clearGroups", @onClearGroups, ...
        "testSettingsChanged", @onTestSettingsChanged, ...
        "runComparisons", @onRunComparisons, ...
        "plotChanged", @onPlotChanged, ...
        "exportData", @onExportData, ...
        "exportResult", @onExportResult);
end

function state = onOpenSource(state, event, services)
    paths = services.events.paths(event, "addedFiles");
    if isempty(paths)
        paths = services.events.paths(event, "files");
    end
    if isempty(paths)
        return;
    end
    filepath = paths(end);
    try
        source = ttest_wizard.sourceTable.readSourceTable(filepath);
    catch ME
        services.diagnostics.report("Open source table", ME);
        services.dialogs.alert(ME.message, "Open table");
        state = services.workflow.log(state, ...
            "Could not open table: " + string(ME.message));
        return;
    end
    state.project.inputs.sources = services.project.reconcileSources( ...
        state.project.inputs.sources, filepath, "table", "table", true);
    state.project.inputs.sourceSheet = source.sheet;
    state.session.cache.source = source;
    state.session.selection.sourceCells = zeros(0, 2);
    state.session.selection.selectionMessage = ...
        "Select numeric cells in the opened table.";
    state = services.workflow.log(state, ...
        "Opened table: " + source.displayName + " | " + source.message);
end

function state = onClearSource(state, ~, services)
    state.project.inputs.sources = services.project.reconcileSources( ...
        state.project.inputs.sources, strings(0, 1), ...
        "table", "table", true);
    state.project.inputs.sourceSheet = "(no source)";
    state.session.cache.source = ttest_wizard.sourceTable.emptySource();
    state.session.selection.sourceCells = zeros(0, 2);
    state.session.selection.selectionMessage = ...
        "Open a table or enter data directly below.";
    state = services.workflow.log(state, ...
        "Cleared the source table; analysis data were kept.");
end

function state = onSheetChanged(state, event, services)
    source = state.session.cache.source;
    if ~source.ok || isempty(state.project.inputs.sources)
        return;
    end
    requested = string(event.value);
    if ~isscalar(requested) || ~any(requested == source.sheetNames)
        requested = source.sheetNames(1);
    end
    filepath = labkit.ui.runtime.sourcePaths( ...
        state.project.inputs.sources(1));
    try
        source = ttest_wizard.sourceTable.readSourceTable( ...
            filepath, requested);
    catch ME
        services.diagnostics.report("Change worksheet", ME);
        services.dialogs.alert(ME.message, "Worksheet");
        return;
    end
    state.project.inputs.sourceSheet = source.sheet;
    state.session.cache.source = source;
    state.session.selection.sourceCells = zeros(0, 2);
    state.session.selection.selectionMessage = ...
        "Select numeric cells in the new worksheet.";
    state = services.workflow.log(state, "Worksheet: " + source.sheet);
end

function state = onSourceSelectionChanged(state, event, services)
    indices = services.events.entries(event, "indices");
    if ~isnumeric(indices) || size(indices, 2) ~= 2
        indices = zeros(0, 2);
    end
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

function state = onAnalysisSelectionChanged(state, event, services)
    indices = services.events.entries(event, "indices");
    if ~isnumeric(indices) || size(indices, 2) ~= 2
        indices = zeros(0, 2);
    end
    state.session.selection.analysisCells = double(indices);
end

function state = onCaptureGroup(state, ~, services)
    source = state.session.cache.source;
    indices = state.session.selection.sourceCells;
    if ~source.ok || isempty(indices)
        services.dialogs.alert( ...
            "Select cells in the opened table first.", "Select data");
        return;
    end
    selection = ttest_wizard.sourceTable.extractNumericSelection( ...
        source.cells, indices);
    state.session.selection.selectionMessage = selection.message;
    if ~selection.ok
        services.dialogs.alert(selection.message, ...
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
    state = services.workflow.log(state, sprintf( ...
        'Added %d value(s) to %s.', ...
        selection.acceptedCount, groups(groupIndex).label));
end

function state = onAssignRowsToGroup(state, ~, services)
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
    state = services.workflow.log(state, sprintf( ...
        'Changed %d selected row(s) to %s.', ...
        numel(selectedRows), target));
end

function state = onDeleteSelectedRows(state, ~, services)
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
    state = services.workflow.log(state, sprintf( ...
        'Deleted %d selected row(s).', numel(selectedRows)));
end

function state = onGroupsEdited(state, event, services)
    data = event.value;
    if ~iscell(data) || size(data, 2) < 2
        services.dialogs.alert( ...
            "The data table must contain Group and Value columns.", ...
            "Edit analysis data");
        return;
    end
    [groups, ok, message] = groupsFromRows( ...
        data(:, 1), data(:, 2), state.project.inputs.groups);
    if ~ok
        services.dialogs.alert(message, "Edit analysis data");
        return;
    end
    state.project.inputs.groups = groups;
    if ~any([groups.label] == string( ...
            state.project.parameters.captureTarget))
        state.project.parameters.captureTarget = "(new group)";
    end
    state = dataChanged(state);
    state = services.workflow.log(state, sprintf( ...
        'Updated analysis data: %d group(s), %d value(s).', ...
        numel(groups), sum(arrayfun( ...
        @(group) numel(group.values), groups))));
end

function state = onClearGroups(state, ~, services)
    state.project.inputs.groups = repmat(emptyGroup("Group 1"), 0, 1);
    state.project.parameters.captureTarget = "(new group)";
    state.session.selection.analysisCells = zeros(0, 2);
    state.session.selection.batchGroupTarget = "(select group)";
    state = dataChanged(state);
    state = services.workflow.log(state, "Cleared all analysis data.");
end

function state = dataChanged(state)
    state.project.results.lastDataExport = "";
end

function state = onTestSettingsChanged(state, ~, services)
    alpha = double(state.project.parameters.alpha);
    if ~isscalar(alpha) || ~isfinite(alpha) || alpha <= 0 || alpha >= 1
        state.project.parameters.alpha = 0.05;
        services.dialogs.alert( ...
            "Alpha must be between zero and one. It was reset to 0.05.", ...
            "Test settings");
    end
end

function state = onRunComparisons(state, ~, services)
    groups = state.project.inputs.groups;
    if numel(groups) < 2
        services.dialogs.alert( ...
            "Enter at least two groups before running comparisons.", ...
            "T-tests");
        return;
    end
    results = ttest_wizard.testRun.runGroupTTests( ...
        groups, currentTestOptions(state));
    state.project.results.current = results;
    state.project.results.lastResultExport = "";
    okCount = sum([results.ok]);
    state = services.workflow.log(state, sprintf( ...
        'Completed %d of %d comparison(s) against %s.', ...
        okCount, numel(results), groups(1).label));
    if okCount < numel(results)
        failed = results(~[results.ok]);
        services.dialogs.alert(strjoin(unique([failed.message]), newline), ...
            "Some t-tests were not completed");
    end
end

function state = onPlotChanged(state, ~, ~)
    % Plot-only settings intentionally do not change the result family.
end

function state = onExportData(state, ~, services)
    groups = state.project.inputs.groups;
    if isempty(groups)
        services.dialogs.alert( ...
            "Enter group data before exporting.", "Export data");
        return;
    end
    [filepath, cancelled] = services.dialogs.outputFile( ...
        {'*.csv', 'CSV table (*.csv)'}, ...
        "Export group data", "ttest_group_data.csv");
    if cancelled
        return;
    end
    filepath = ensureCsvExtension(filepath);
    try
        ttest_wizard.sourceTable.writeGroupCsv(filepath, groups);
    catch ME
        services.diagnostics.report("Export group data", ME);
        services.dialogs.alert(ME.message, "Export data");
        return;
    end
    state.project.results.lastDataExport = string(filepath);
    state = services.workflow.log(state, ...
        "Exported group data: " + string(filepath));
end

function state = onExportResult(state, ~, services)
    results = state.project.results.current;
    if isempty(results)
        services.dialogs.alert( ...
            "Run comparisons before exporting results.", "Export results");
        return;
    end
    [filepath, cancelled] = services.dialogs.outputFile( ...
        {'*.csv', 'CSV table (*.csv)'}, ...
        "Export t-test results", "ttest_results.csv");
    if cancelled
        return;
    end
    filepath = ensureCsvExtension(filepath);
    try
        ttest_wizard.resultFiles.writeResultCsv(filepath, results);
    catch ME
        services.diagnostics.report("Export t-test results", ME);
        services.dialogs.alert(ME.message, "Export results");
        return;
    end
    state.project.results.lastResultExport = string(filepath);
    state = services.workflow.log(state, ...
        "Exported t-test results: " + string(filepath));
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
    rowOffset = 0;
    movedValues = zeros(0, 1);
    movedAddresses = strings(0, 1);
    for groupIndex = 1:numel(groups)
        count = numel(groups(groupIndex).values);
        visibleRows{groupIndex} = rowOffset + (1:count);
        rowOffset = rowOffset + count;
        move = ismember(visibleRows{groupIndex}, selectedRows);
        if groups(groupIndex).label ~= target
            movedValues = [movedValues; ...
                groups(groupIndex).values(move)]; %#ok<AGROW>
            addresses = string(groups(groupIndex).cellAddresses(:));
            if numel(addresses) == count
                movedAddresses = [movedAddresses; addresses(move)]; %#ok<AGROW>
                groups(groupIndex).cellAddresses = addresses(~move);
            end
            groups(groupIndex).values = groups(groupIndex).values(~move);
        end
    end
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
