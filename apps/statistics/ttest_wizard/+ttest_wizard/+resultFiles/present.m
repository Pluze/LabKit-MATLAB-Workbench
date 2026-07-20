% App-owned implementation for ttest_wizard.resultFiles.present within the ttest_wizard product workflow.
function view = present(groups, results, lastDataExport, lastResultExport)
%PRESENT Describe export availability and last destinations.
%
% Outputs:
%   view - Snapshot fragment for result-file controls.

view = labkit.app.view.Snapshot() ...
    .enabled("exportData", ~isempty(groups)) ...
    .enabled("exportResult", ~isempty(results)) ...
    .text("lastDataExport", exportText(lastDataExport)) ...
    .text("lastResultExport", exportText(lastResultExport));
end

function text = exportText(value)
value = string(value);
if strlength(value) == 0
    text = "Not exported";
else
    text = value;
end
end
