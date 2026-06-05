% Expected caller: CIC app runner and export tests. Inputs are item structs and
% display unit label. Output is the stable CIC CSV result table. No file side
% effects.
function T = buildResultsTable(items, unitLabel)
    T = cic.core.dispatch("buildResultsTable", items, unitLabel);
end
