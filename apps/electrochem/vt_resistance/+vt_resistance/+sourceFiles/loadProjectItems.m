% Expected caller: VT Resistance session creation. Inputs are resolved source
% records and durable parameters. Output is the rebuildable decoded and
% analyzed DTA item vector; invalid required sources raise an app error.
function items = loadProjectItems(sources, parameters)
    items = struct([]);
    opts = vt_resistance.analysisRun.optionsFromParameters(parameters);
    paths = labkit.ui.runtime.sourcePaths(sources);
    for k = 1:numel(sources)
        filepath = paths(k);
        [item, status] = labkit.dta.loadFile(filepath, "chrono");
        if ~status.ok
            error('vt_resistance:SourceLoadFailed', ...
                'Could not load %s: %s', filepath, status.message);
        end
        item.analysis = vt_resistance.analysisRun.computeResistance(item, opts);
        if isempty(items)
            items = item;
        else
            items(end + 1) = item;
        end
    end
end
