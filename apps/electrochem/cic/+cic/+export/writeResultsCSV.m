% Expected caller: CIC app runner and export tests. Inputs are item structs,
% output filepath, and display unit label. Side effect is writing the stable CIC
% CSV file.
function [ok, msg] = writeResultsCSV(items, filepath, unitLabel)
    [ok, msg] = cic.core.dispatch("writeResultsCSV", items, filepath, unitLabel);
end
