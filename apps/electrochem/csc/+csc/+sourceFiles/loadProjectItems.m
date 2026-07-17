% Expected caller: CSC session creation. Input is resolved DTA source
% records. Output is decoded CV/CT items; invalid required sources throw.
function items = loadProjectItems(sources)
    items = struct([]);
    paths = labkit.ui.runtime.sourcePaths(sources);
    for k = 1:numel(sources)
        filepath = paths(k);
        [item, status] = labkit.dta.loadFile(filepath, "cvct");
        if ~status.ok
            error('csc:SourceLoadFailed', 'Could not load %s: %s', ...
                filepath, status.message);
        end
        if isempty(items)
            items = item;
        else
            items(end + 1) = item;
        end
    end
end
