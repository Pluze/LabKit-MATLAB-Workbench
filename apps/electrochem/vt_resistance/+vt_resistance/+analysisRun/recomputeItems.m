% Expected caller: VT resistance app actions and tests. Inputs are loaded DTA
% item structs and one shared resistance option struct. Output contains every
% item recomputed with exactly those options. Side effects are none.
function items = recomputeItems(items, opts)
    for index = 1:numel(items)
        items(index).analysis = ...
            vt_resistance.analysisRun.computeResistance(items(index), opts);
    end
end
