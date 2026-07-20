% App-owned implementation for ttest_wizard.testRun.present within the ttest_wizard product workflow.
function view = present(groups, results, options, resultsCurrent)
%PRESENT Describe test readiness and the latest comparison family.
%
% Inputs:
%   groups - Ordered durable group struct array.
%   results - Latest comparison result struct array.
%   options - Current method, alternative, and alpha struct.
%   resultsCurrent - Logical scalar freshness result.
%
% Outputs:
%   view - Snapshot fragment for test and result controls.

view = labkit.app.view.Snapshot() ...
    .text("pendingTest", pendingText(groups, options.method)) ...
    .enabled("runComparisons", canRun(groups)) ...
    .text("resultStatus", join( ...
        resultStatusText(results, resultsCurrent), newline)) ...
    .tableData("resultTable", resultTableData(results), ...
        Columns=["Comparison", "Difference", "p", ...
            "Significance", "Status"]);
end

function text = pendingText(groups, method)
if numel(groups) < 2
    text = sprintf( ...
        '%d group(s) ready. Enter at least two; the first is reference.', ...
        numel(groups));
    return;
end
counts = arrayfun(@(group) numel(group.values), groups);
method = string(method);
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

function text = significanceText(result)
% Conventional star thresholds for reported p-values.
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
