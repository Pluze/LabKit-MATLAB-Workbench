% Expected caller: labkit_ImageEnhance_app listbox/reference controls. Input is
% a loaded item array. Output is a cell array of stable display labels.
function names = displayImageNames(items)

    if isempty(items)
        names = {'No images loaded'};
        return;
    end

    names = cell(numel(items), 1);
    for k = 1:numel(items)
        names{k} = sprintf('%d. %s', k, char(items(k).name));
    end
end
