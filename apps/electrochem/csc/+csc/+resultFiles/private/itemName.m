function name = itemName(item)
    if isfield(item, 'name')
        name = item.name;
    elseif isfield(item, 'filepath')
        [~, name, ext] = fileparts(item.filepath);
        name = [name ext];
    else
        name = "";
    end
end
