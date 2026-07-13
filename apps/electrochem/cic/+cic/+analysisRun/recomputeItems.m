% Expected caller: CIC app actions and tests. Inputs are loaded DTA item
% structs and one shared CIC option struct. Output contains every item
% recomputed with exactly those options. Side effects are none.
function items = recomputeItems(items, opts)
    for index = 1:numel(items)
        items(index).analysis = cic.analysisRun.computeCIC(items(index), opts);
    end
end
