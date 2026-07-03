% DIC Postprocess view helper. Expected caller: labkit_DICPostprocess_app.
% Input is the ROI strain summary table. Output is UI table cell data.
% Side effects: none.
function data = summaryTableData(T)
    if isempty(T) || height(T) == 0
        data = {};
        return;
    end
    data = [cellstr(T.Metric), num2cell(T.EXX), num2cell(T.EYY)];
end
