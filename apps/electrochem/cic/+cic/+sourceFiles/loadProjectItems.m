% Expected callers: CIC session creation. Inputs are resolved source records
% and durable analysis parameters. Output is the rebuildable decoded and
% analyzed DTA item vector; invalid required sources raise an app error.
function items = loadProjectItems(sources, parameters)
    opts = cic.analysisRun.optionsFromParameters(parameters);
    paths = string(sources);
    itemCells = cell(1, numel(paths));
    for k = 1:numel(sources)
        filepath = paths(k);
        [item, status] = labkit.dta.loadFile(filepath, "chrono");
        if ~status.ok
            error('cic:SourceLoadFailed', 'Could not load %s: %s', ...
                filepath, status.message);
        end
        item.analysis = cic.analysisRun.computeCIC(item, opts);
        itemCells{k} = item;
    end
    items = struct([]);
    if ~isempty(itemCells)
        items = [itemCells{:}];
    end
end
