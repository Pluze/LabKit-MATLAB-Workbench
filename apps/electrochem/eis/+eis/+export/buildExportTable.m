% Expected caller: EIS app runner and export tests. Inputs are EIS item structs,
% axis labels, and log flags. Output is the stable EIS export table. No file side
% effects.
function T = buildExportTable(items, xName, yName, useLogX, useLogY)
    T = eis.core.dispatch("buildExportTable", items, xName, yName, useLogX, useLogY);
end
