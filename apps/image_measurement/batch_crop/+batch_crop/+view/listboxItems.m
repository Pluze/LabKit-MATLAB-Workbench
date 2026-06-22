% App-owned list display helper. Expected caller: batch-crop app refreshList.
% Input is an item struct vector. Output is listbox display text and has no
% side effects.
function items = listboxItems(cropItems, scaleMode)
%LISTBOXITEMS Build listbox labels for loaded crop items.

    if nargin < 2
        scaleMode = "Pixels";
    end
    items = cell(numel(cropItems), 1);
    for k = 1:numel(cropItems)
        marker = ternary(cropItems(k).centerSet, 'set', 'needs center');
        if strcmpi(string(scaleMode), "Physical")
            scaleMarker = ternary(hasScaleCalibration(cropItems(k)), ...
                'scale set', 'needs scale');
            marker = sprintf('%s, %s', marker, scaleMarker);
        end
        items{k} = sprintf('%02d  %s  [%s]', k, ...
            batch_crop.view.displayNameFromPath(cropItems(k).path), marker);
    end
end

function tf = hasScaleCalibration(item)
    tf = isfield(item, 'scaleCalibration') && isstruct(item.scaleCalibration) && ...
        isfield(item.scaleCalibration, 'isCalibrated') && item.scaleCalibration.isCalibrated;
end

function value = ternary(condition, trueValue, falseValue)
    if condition
        value = trueValue;
    else
        value = falseValue;
    end
end
