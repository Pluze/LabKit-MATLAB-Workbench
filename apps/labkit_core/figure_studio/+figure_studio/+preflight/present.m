%PRESENT Build deterministic preflight summary and issue rows.
function view = present(document, style, hasFigure)
if ~hasFigure
    summary = "No figure loaded";
    data = cell(0, 6);
else
    report = figure_studio.preflight.check(document, style);
    summary = upper(report.status) + " — " + string(report.errors) + ...
        " errors, " + string(report.warnings) + " warnings";
    data = issueData(report.issues);
end
view = labkit.app.view.Snapshot().text("preflightSummary", summary) ...
    .tableData("preflightTable", data, Columns=["Severity", "Code", ...
        "Panel", "Object", "Issue", "Fix"], ...
        RowNames=string(1:size(data, 1)));
end

function data = issueData(issues)
data = cell(numel(issues), 6);
for k = 1:numel(issues)
    data(k, :) = {char(issues(k).severity), char(issues(k).code), ...
        char(issues(k).panelId), char(issues(k).nodeId), ...
        char(issues(k).message), char(issues(k).suggestedFix)};
end
end
