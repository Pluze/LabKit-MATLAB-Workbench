%HISTORY Create, commit, undo, or redo serializable document snapshots.
function [historyValue, document] = history(action, historyValue, document, label)
action = lower(string(action));
if nargin < 2 || isempty(historyValue)
    historyValue = struct("past", {{}}, "future", {{}}, ...
        "labels", strings(0, 1), "futureLabels", strings(0, 1));
end
if nargin < 3
    document = [];
end
if nargin < 4
    label = "Edit";
end
switch action
    case "create"
        return;
    case "commit"
        historyValue.past{end + 1, 1} = document;
        historyValue.labels(end + 1, 1) = string(label);
        historyValue.future = {};
        historyValue.futureLabels = strings(0, 1);
    case "undo"
        if isempty(historyValue.past)
            return;
        end
        historyValue.future{end + 1, 1} = document;
        if isempty(historyValue.labels)
            historyValue.futureLabels(end + 1, 1) = "Edit";
        else
            historyValue.futureLabels(end + 1, 1) = historyValue.labels(end);
            historyValue.labels(end) = [];
        end
        document = historyValue.past{end};
        historyValue.past(end) = [];
    case "redo"
        if isempty(historyValue.future)
            return;
        end
        historyValue.past{end + 1, 1} = document;
        if isempty(historyValue.futureLabels)
            historyValue.labels(end + 1, 1) = "Edit";
        else
            historyValue.labels(end + 1, 1) = historyValue.futureLabels(end);
            historyValue.futureLabels(end) = [];
        end
        document = historyValue.future{end};
        historyValue.future(end) = [];
    otherwise
        error("figure_studio:figureDocument:UnknownHistoryAction", ...
            "Unknown history action: %s", action);
end
end
