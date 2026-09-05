% App-owned implementation for ttest_wizard.resultPlot.present within the ttest_wizard product workflow.
function view = present(results, parameters, resultsCurrent, viewRevision, groupOrder)
%PRESENT Describe plot freshness, renderer model, and style availability.
%
% Inputs:
%   results - Latest comparison result struct array.
%   parameters - Current plot-parameter struct.
%   resultsCurrent - Logical scalar indicating data/test freshness.
%   viewRevision - Nonnegative transient revision for explicit view resets.
%
% Outputs:
%   view - Snapshot fragment for plot controls and resultPlot.

if nargin < 5, groupOrder = strings(0, 1); end
hasResult = ~isempty(results) && any([results.ok]);
view = labkit.app.view.Snapshot() ...
    .text("plotFreshness", freshnessText(results, resultsCurrent)) ...
    .renderPlot("resultPlot", plotModel(results, parameters, groupOrder), ...
        ViewRevision=ttest_wizard.resultPlot.viewportRevision( ...
            parameters.type, viewRevision, hasResult));
controlIds = ["plotType", "showPoints", "showSummary", ...
    "showPValue", "plotTitle", "yLabel", "resetPlotView"];
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

function model = plotModel(results, parameters, groupOrder)
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
[found, indices] = ismember(groupOrder, string({model.groups.label}));
indices = indices(found);
remaining = setdiff(1:numel(model.groups), indices, "stable");
model.groups = model.groups([indices(:).' remaining]);
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
