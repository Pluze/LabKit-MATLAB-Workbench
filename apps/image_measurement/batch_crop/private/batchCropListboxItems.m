% App-owned list display helper. Expected caller: batch-crop app refreshList.
% Input is an item struct vector. Output is listbox display text and has no
% side effects.
function items = batchCropListboxItems(cropItems)
%BATCHCROPLISTBOXITEMS Build listbox labels for loaded crop items.

    items = cell(numel(cropItems), 1);
    for k = 1:numel(cropItems)
        marker = ternary(cropItems(k).centerSet, 'set', 'needs center');
        items{k} = sprintf('%02d  %s  [%s]', k, ...
            displayNameFromPath(cropItems(k).path), marker);
    end
end

function value = ternary(condition, trueValue, falseValue)
    if condition
        value = trueValue;
    else
        value = falseValue;
    end
end
