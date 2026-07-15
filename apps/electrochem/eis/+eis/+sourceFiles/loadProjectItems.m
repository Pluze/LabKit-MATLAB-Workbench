% Expected caller: EIS session creation. Input is resolved EIS source records.
% Output is decoded EIS items; invalid required sources raise an app error.
function items = loadProjectItems(sources)
    items = struct([]);
    for k = 1:numel(sources)
        filepath = string(sources(k).reference.originalPath);
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
