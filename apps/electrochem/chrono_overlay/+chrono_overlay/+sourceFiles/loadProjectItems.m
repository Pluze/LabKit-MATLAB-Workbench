% Expected caller: Chrono Overlay session creation. Input is canonical source
% records. Output is the rebuildable decoded and pulse-aligned DTA item vector.
function items = loadProjectItems(sources)
    items = struct([]);
    for k = 1:numel(sources)
        filepath = string(sources(k).reference.originalPath);
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
