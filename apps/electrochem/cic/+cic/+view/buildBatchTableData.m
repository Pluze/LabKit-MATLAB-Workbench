% Expected caller: CIC app runner and unit tests. Inputs are item structs and a
% display unit label. Outputs are the stable UI table cell data and column names.
% No file side effects.
function [C, columnNames] = buildBatchTableData(items, unitLabel)
    [C, columnNames] = cic.core.dispatch("buildBatchTableData", items, unitLabel);
end
