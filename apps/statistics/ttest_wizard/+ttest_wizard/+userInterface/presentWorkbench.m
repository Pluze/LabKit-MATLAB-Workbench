% App presenter; maps editable groups and result freshness to the workbench.
function view = presentWorkbench(state)
%PRESENTWORKBENCH Present source data, analysis rows, results, and plot state.
%
% Expected caller: Runtime. Input is canonical App state. Output updates
% source cells, the editable Group/Value table, capture-target choices,
% comparison results, plot freshness, export state, and one prepared mean/SD
% plot model. Side effects are none.

    source = state.session.cache.source;
    groups = state.project.inputs.groups;
    results = state.project.results.current;
    options = currentTestOptions(state);
    resultsCurrent = ttest_wizard.testRun.resultsMatchGroups( ...
        results, groups, options);

    view = struct();
    view.controls.sourceFile = sourceFileSpec(state, source);
    view.controls.sourceSheet = sourceSheetSpec(source);
    view.controls.sourceSummary = valueSpec(source.message);
    view.controls.selectionSummary = valueSpec( ...
        state.session.selection.selectionMessage);
    view.controls.captureTarget = captureTargetSpec( ...
        state.project.parameters.captureTarget, groups);
    view.controls.captureGroup = enabledSpec( ...
        source.ok && ~isempty(state.session.selection.sourceCells));
    view.controls.batchGroupTarget = batchGroupTargetSpec( ...
        state.session.selection.batchGroupTarget, groups);
    view.controls.assignRowsToGroup = enabledSpec( ...
        ~isempty(groups) && ~isempty(state.session.selection.analysisCells) && ...
        state.session.selection.batchGroupTarget ~= "(select group)");
    view.controls.deleteSelectedRows = enabledSpec( ...
        hasSelectedObservationRows(state, groups));
    view.controls.clearGroups = enabledSpec(~isempty(groups));
    view.controls.dataTable = tableSpec(observationRows(groups));
    view.controls.pendingTest = valueSpec(pendingTestText(state));
    view.controls.runComparisons = enabledSpec(canRun(groups));
    view.controls.resultStatus = valueSpec( ...
        resultStatusText(results, resultsCurrent));
    view.controls.resultTable = tableSpec(resultTableData(results));
    view.controls.plotFreshness = valueSpec( ...
        plotFreshnessText(results, resultsCurrent));

    hasResult = ~isempty(results) && any([results.ok]);
    plotControlIds = ["plotType", "showPoints", "showSummary", ...
        "showPValue", "plotTitle", "yLabel"];
    for k = 1:numel(plotControlIds)
        view.controls.(char(plotControlIds(k))) = enabledSpec(hasResult);
    end
    view.controls.exportData = enabledSpec(~isempty(groups));
    view.controls.exportResult = enabledSpec(~isempty(results));
    view.controls.lastDataExport = valueSpec(exportText( ...
        state.project.results.lastDataExport));
    view.controls.lastResultExport = valueSpec(exportText( ...
        state.project.results.lastResultExport));

    [sourceData, columnNames, rowNames] = sourceTablePresentation(source);
    view.controls.sourceGrid = struct( ...
        "ColumnName", {columnNames}, ...
        "RowName", {rowNames}, ...
        "Data", {sourceData});
    view.previews.resultPlot = struct( ...
        "Renderer", "resultPreview", ...
        "Model", plotModel(results, state.project.parameters.plot));
end

function spec = sourceFileSpec(state, source)
    files = struct("id", {}, "path", {}, "status", {});
    paths = labkit.ui.runtime.sourcePaths(state.project.inputs.sources);
    if ~isempty(paths)
        files = struct("id", "item1", "path", paths(1), "status", "");
    end
    spec = struct("Files", files);
    if source.ok
        spec.Status = source.displayName;
    else
        spec.Status = "No table open";
    end
end

function spec = sourceSheetSpec(source)
    items = cellstr(source.sheetNames);
    spec = struct( ...
        "Items", {items}, ...
        "Value", source.sheet, ...
        "Enabled", source.ok && numel(items) > 1);
end

function spec = captureTargetSpec(value, groups)
    items = ["(new group)", [groups.label]];
    value = string(value);
    if ~any(items == value)
        value = items(1);
    end
    spec = struct("Items", {cellstr(items)}, "Value", value);
end

function spec = batchGroupTargetSpec(value, groups)
    items = ["(select group)", [groups.label]];
    value = string(value);
    if ~any(items == value)
        value = items(1);
    end
    spec = struct( ...
        "Items", {cellstr(items)}, ...
        "Value", value, ...
        "Enabled", ~isempty(groups));
end

function [data, columns, rows] = sourceTablePresentation(source)
    if source.ok && source.rowCount > 0 && source.columnCount > 0
        data = source.cells;
        columns = source.columnNames;
        rows = source.rowNames;
    else
        data = {'Open a CSV or workbook from the Data controls.'};
        columns = {'A'};
        rows = {'1'};
    end
end

function data = observationRows(groups)
    valueCount = sum(arrayfun(@(group) numel(group.values), groups));
    blankRows = 8;
    data = cell(valueCount + blankRows, 2);
    row = 0;
    for groupIndex = 1:numel(groups)
        for valueIndex = 1:numel(groups(groupIndex).values)
            row = row + 1;
            data{row, 1} = char(groups(groupIndex).label);
            data{row, 2} = groups(groupIndex).values(valueIndex);
        end
    end
    for k = row + 1:size(data, 1)
        data{k, 1} = '';
        data{k, 2} = '';
    end
end

function text = pendingTestText(state)
    groups = state.project.inputs.groups;
    if numel(groups) < 2
        text = sprintf( ...
            '%d group(s) ready. Enter at least two; the first is reference.', ...
            numel(groups));
        return;
    end
    counts = arrayfun(@(group) numel(group.values), groups);
    method = string(state.project.parameters.testMethod);
    if contains(method, "Paired") && any(counts(2:end) ~= counts(1))
        text = sprintf( ...
            'Paired testing needs every group to match reference samples (%d).', ...
            counts(1));
    else
        text = sprintf( ...
            'Run %d comparison(s) against %s using %s.', ...
            numel(groups) - 1, groups(1).label, method);
    end
end

function tf = canRun(groups)
    tf = numel(groups) >= 2 && ...
        all(arrayfun(@(group) numel(group.values) >= 2, groups));
end

function tf = hasSelectedObservationRows(state, groups)
    selected = state.session.selection.analysisCells;
    observationCount = sum(arrayfun(@(group) numel(group.values), groups));
    tf = isnumeric(selected) && size(selected, 2) == 2 && ...
        any(selected(:, 1) >= 1 & selected(:, 1) <= observationCount);
end

function text = resultStatusText(results, isCurrent)
    if isempty(results)
        text = "No comparisons have been run.";
        return;
    end
    text = string(sprintf( ...
        '%d of %d comparison(s) completed against %s.', ...
        sum([results.ok]), numel(results), results(1).labelA));
    if ~isCurrent
        text = [text; ...
            "Data or test settings changed; run again to refresh."];
    end
end

function data = resultTableData(results)
    if isempty(results)
        data = {'Not run', '', '', '', ''};
        return;
    end
    data = cell(numel(results), 5);
    for k = 1:numel(results)
        result = results(k);
        data(k, :) = { ...
            char(result.labelB + " vs " + result.labelA), ...
            formatNumber(result.meanDifference), ...
            formatNumber(result.pValue), ...
            char(significanceText(result)), ...
            char(result.status)};
    end
end

function text = plotFreshnessText(results, isCurrent)
    if isempty(results) || ~any([results.ok])
        text = "No plot yet. Run comparisons after entering at least two groups.";
    elseif isCurrent
        text = "Current - plot and results match the analysis data.";
    else
        text = "OUT OF DATE - data or test settings changed. " + ...
            "Run / refresh comparisons.";
    end
end

function text = significanceText(result)
    if ~result.ok
        text = "";
    elseif result.pValue < 1e-4
        text = "****";
    elseif result.pValue < 1e-3
        text = "***";
    elseif result.pValue < 1e-2
        text = "**";
    elseif result.pValue < result.alpha
        text = "*";
    else
        text = "NS";
    end
end

function model = plotModel(results, plotParameters)
    ready = ~isempty(results) && any([results.ok]);
    model = struct( ...
        "ready", ready, ...
        "message", "Enter data and run comparisons to create the plot.", ...
        "groups", repmat(struct( ...
        "label", "", "values", zeros(0, 1)), 0, 1), ...
        "results", results, ...
        "parameters", plotParameters, ...
        "means", zeros(0, 1), ...
        "standardDeviations", zeros(0, 1));
    if ~ready
        return;
    end
    model.groups = snapshotsFromResults(results);
    model.means = arrayfun(@(group) mean(group.values), model.groups);
    model.standardDeviations = arrayfun( ...
        @(group) std(group.values, 0), model.groups);
end

function groups = snapshotsFromResults(results)
    groups = repmat(struct("label", "", "values", zeros(0, 1)), ...
        numel(results) + 1, 1);
    groups(1).label = results(1).labelA;
    groups(1).values = results(1).vectorA;
    for k = 1:numel(results)
        groups(k + 1).label = results(k).labelB;
        groups(k + 1).values = results(k).vectorB;
    end
end

function options = currentTestOptions(state)
    options = struct( ...
        "method", state.project.parameters.testMethod, ...
        "alternative", state.project.parameters.alternative, ...
        "alpha", state.project.parameters.alpha);
end

function spec = valueSpec(value)
    spec = struct("Value", value);
end

function spec = tableSpec(value)
    spec = struct("Data", {value});
end

function spec = enabledSpec(value)
    spec = struct("Enabled", logical(value));
end

function text = exportText(value)
    value = string(value);
    if strlength(value) == 0
        text = "Not exported";
    else
        text = value;
    end
end

function value = formatNumber(value)
    if isempty(value) || isnan(value)
        value = '';
    elseif isinf(value)
        if value > 0
            value = 'Inf';
        else
            value = '-Inf';
        end
    else
        value = sprintf('%.10g', value);
    end
end
