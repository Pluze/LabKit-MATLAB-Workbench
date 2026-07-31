% Expected caller: CSC session creation. Input is resolved DTA source
% records. Output is decoded CV/CT items; invalid required sources throw.
function items = loadProjectItems(sources)
    paths = string(sources);
    itemCells = cell(1, numel(paths));
    for k = 1:numel(sources)
        filepath = paths(k);
        [item, status] = labkit.dta.loadFile(filepath, "cvct");
        if ~status.ok
            error('csc:SourceLoadFailed', 'Could not load %s: %s', ...
                filepath, status.message);
        end
        itemCells{k} = item;
    end
    items = struct([]);
    if ~isempty(itemCells)
        items = [itemCells{:}];
    end
end
