% App-owned DIC helper extracted from labkit_DICPostprocess_app.m. Expected caller: DIC app entrypoints.
% Inputs, outputs, and side effects match the original local helper implementation.
function data = summaryTableData(T)
    if isempty(T) || height(T) == 0
        data = {};
        return;
    end
    data = [cellstr(T.Metric), num2cell(T.EXX), num2cell(T.EYY)];
end
