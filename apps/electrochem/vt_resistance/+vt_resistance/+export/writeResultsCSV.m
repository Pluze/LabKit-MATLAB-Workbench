% Expected caller: VT resistance app runner and export tests. Inputs are item
% structs and output filepath. Side effect is writing the stable VT CSV file.
function [ok, msg] = writeResultsCSV(items, filepath)
    [ok, msg] = vt_resistance.core.dispatch("writeResultsCSV", items, filepath);
end
