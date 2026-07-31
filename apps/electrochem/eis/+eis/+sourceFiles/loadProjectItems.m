% Expected caller: EIS session creation. Input is resolved EIS source records.
% Output is decoded EIS items; invalid required sources raise an app error.
function items = loadProjectItems(paths)
    paths = string(paths);
    itemCells = cell(1, numel(paths));
    for k = 1:numel(paths)
        filepath = paths(k);
        [item, status] = labkit.dta.loadFile(filepath, "eis");
        if ~status.ok
            error('eis:SourceLoadFailed', 'Could not load %s: %s', ...
                filepath, status.message);
        end
        itemCells{k} = item;
    end
    items = struct([]);
    if ~isempty(itemCells)
        items = [itemCells{:}];
    end
end
