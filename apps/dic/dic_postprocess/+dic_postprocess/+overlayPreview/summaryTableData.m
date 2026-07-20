% App-owned implementation for dic_postprocess.overlayPreview.summaryTableData within the dic_postprocess product workflow.
function data = summaryTableData(summary)
%SUMMARYTABLEDATA Convert the scientific summary to display cell data.
if isempty(summary) || height(summary) == 0
    data = {};
    return;
end
data = [cellstr(summary.Metric), ...
    num2cell(summary.EXX), num2cell(summary.EYY)];
end
