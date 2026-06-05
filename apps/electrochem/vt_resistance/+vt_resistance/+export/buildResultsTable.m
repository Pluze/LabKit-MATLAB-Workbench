% Expected caller: VT resistance app runner and export tests. Input is item
% structs. Output is the stable VT resistance CSV result table. No file side
% effects.
function T = buildResultsTable(items)
    T = vt_resistance.core.dispatch("buildResultsTable", items);
end
