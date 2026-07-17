% Expected caller: EIS session creation. Input is resolved EIS source records.
% Output is decoded EIS items; invalid required sources raise an app error.
function items = loadProjectItems(sources)
    items = struct([]);
    paths = labkit.ui.runtime.sourcePaths(sources);
    for k = 1:numel(sources)
        filepath = paths(k);
        [item, status] = labkit.dta.loadFile(filepath, "eis");
        if ~status.ok
            error('eis:SourceLoadFailed', 'Could not load %s: %s', ...
                filepath, status.message);
        end
        if isempty(items)
            items = item;
        else
            items(end + 1) = item;
        end
    end
end
