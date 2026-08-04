function heights = childRowHeights(obj, ids)
% Class-folder implementation of MatlabPlatformAdapter.childRowHeights.
    nodes = obj.nodes(ids);
    heights = repmat({'fit'}, 1, numel(nodes));
    for k = 1:numel(nodes)
        heights{k} = obj.preferredRowHeight(nodes(k));
    end
end
