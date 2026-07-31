% Expected caller: VT Resistance session creation. Inputs are resolved paths
% and durable parameters. Output is the rebuildable decoded and
% analyzed DTA item vector; invalid required sources raise an app error.
function items = loadProjectItems(sources, parameters)
    opts = vt_resistance.analysisRun.optionsFromParameters(parameters);
    paths = string(sources);
    itemCells = cell(1, numel(paths));
    for k = 1:numel(sources)
        filepath = paths(k);
        [item, status] = labkit.dta.loadFile(filepath, "chrono");
        if ~status.ok
            error('vt_resistance:SourceLoadFailed', ...
                'Could not load %s: %s', filepath, status.message);
        end
        item.analysis = vt_resistance.analysisRun.computeResistance(item, opts);
        itemCells{k} = item;
    end
    items = struct([]);
    if ~isempty(itemCells)
        items = [itemCells{:}];
    end
end
