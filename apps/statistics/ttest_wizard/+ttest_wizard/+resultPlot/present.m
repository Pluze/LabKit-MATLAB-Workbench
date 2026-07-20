% App-owned implementation for ttest_wizard.resultPlot.present within the ttest_wizard product workflow.
function view = present(results, parameters, resultsCurrent)
%PRESENT Describe plot freshness, renderer model, and style availability.
%
% Inputs:
%   results - Latest comparison result struct array.
%   parameters - Current plot-parameter struct.
%   resultsCurrent - Logical scalar indicating data/test freshness.
%
% Outputs:
%   view - Snapshot fragment for plot controls and resultPlot.

hasResult = ~isempty(results) && any([results.ok]);
view = labkit.app.view.Snapshot() ...
    .text("plotFreshness", freshnessText(results, resultsCurrent)) ...
    .renderPlot("resultPlot", plotModel(results, parameters));
controlIds = ["plotType", "showPoints", "showSummary", ...
    "showPValue", "plotTitle", "yLabel"];
for id = controlIds
    view = view.enabled(id, hasResult);
end
end

function text = freshnessText(results, isCurrent)
if isempty(results) || ~any([results.ok])
    text = "No plot yet. Run comparisons after entering at least two groups.";
elseif isCurrent
    text = "Current - plot and results match the analysis data.";
else
    text = "OUT OF DATE - data or test settings changed. " + ...
        "Run / refresh comparisons.";
end
end

function model = plotModel(results, parameters)
ready = ~isempty(results) && any([results.ok]);
model = struct( ...
    "ready", ready, ...
    "message", "Enter data and run comparisons to create the plot.", ...
    "groups", repmat(struct( ...
    "label", "", "values", zeros(0, 1)), 0, 1), ...
    "results", results, ...
    "parameters", parameters, ...
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
