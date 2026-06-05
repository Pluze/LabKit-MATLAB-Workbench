% Expected caller: VT resistance app runner and unit tests. Input is item structs.
% Output is the stable UI table cell data. No file side effects.
function C = buildBatchTableData(items)
    C = vt_resistance.core.dispatch("buildBatchTableData", items);
end
