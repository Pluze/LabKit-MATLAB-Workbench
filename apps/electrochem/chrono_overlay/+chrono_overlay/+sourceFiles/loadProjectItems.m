% Expected caller: Chrono Overlay session creation. Input is runtime-resolved
% paths. Output is the rebuildable decoded and pulse-aligned DTA item vector.
function items = loadProjectItems(paths)
    items = struct([]);
    paths = string(paths(:));
    for k = 1:numel(paths)
        filepath = paths(k);
        [item, status] = labkit.dta.loadFile(filepath, "chrono");
        if ~status.ok
            error('chrono_overlay:SourceLoadFailed', ...
                'Could not load %s: %s', filepath, status.message);
        end
        item = chrono_overlay.sourceFiles.alignByPulseGap(item);
        if isempty(items)
            items = item;
        else
            items(end + 1) = item;
        end
    end
end
