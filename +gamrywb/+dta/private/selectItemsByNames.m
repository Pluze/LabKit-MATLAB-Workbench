function [selectedItems, idx] = selectItemsByNames(items, selectedNames)
%SELECTITEMSBYNAMES Select session items by display names.

    if isempty(items)
        selectedItems = struct([]);
        idx = [];
        return;
    end

    selectedNames = normalizeSelectedNames(selectedNames);
    if isempty(selectedNames)
        idx = 1:numel(items);
        selectedItems = items;
        return;
    end

    if ~isfield(items, 'name')
        idx = [];
        selectedItems = items([]);
        return;
    end

    idx = find(ismember(string({items.name}), selectedNames));
    selectedItems = items(idx);
end

function names = normalizeSelectedNames(selectedNames)
    if isempty(selectedNames)
        names = strings(0, 1);
    elseif ischar(selectedNames)
        names = string({selectedNames});
    elseif isstring(selectedNames)
        names = selectedNames(:);
    elseif iscell(selectedNames)
        names = string(selectedNames(:));
    else
        error('gamrywb:dta:InvalidSelectedNames', ...
            'selectedNames must be a char, string, or cell array.');
    end
end
