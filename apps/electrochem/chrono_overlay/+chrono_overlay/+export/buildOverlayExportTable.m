% Expected caller: chrono overlay app runner and export tests. Inputs are aligned
% chrono item structs. Output is the stable overlay export table. No file side
% effects.
function T = buildOverlayExportTable(items)
    T = chrono_overlay.core.dispatch("buildOverlayExportTable", items);
end
