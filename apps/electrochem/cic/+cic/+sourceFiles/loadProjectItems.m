% Expected callers: CIC session creation. Inputs are resolved source records
% and durable analysis parameters. Output is the rebuildable decoded and
% analyzed DTA item vector; invalid required sources raise an app error.
function items = loadProjectItems(sources, parameters)
    items = struct([]);
    opts = cic.analysisRun.optionsFromParameters(parameters);
    for k = 1:numel(sources)
        filepath = string(sources(k).reference.originalPath);
        [item, status] = labkit.dta.loadFile(filepath, "chrono");
        if ~status.ok
            error('cic:SourceLoadFailed', 'Could not load %s: %s', ...
                filepath, status.message);
        end
        item.analysis = cic.analysisRun.computeCIC(item, opts);
        if isempty(items)
            items = item;
        else
            items(end + 1) = item;
        end
    end
end
