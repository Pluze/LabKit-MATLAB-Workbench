function refreshListboxItems(lb, names)
%REFRESHLISTBOXITEMS Refresh a multiselect listbox and preserve valid picks.

    if isempty(names)
        lb.Items = {};
        lb.Value = {};
        return;
    end

    if isstring(names)
        names = cellstr(names);
    end
    names = reshape(names, 1, []);

    lb.Items = names;
    if isempty(lb.Value)
        lb.Value = names;
        return;
    end

    current = string(lb.Value);
    valid = ismember(current, string(names));
    selected = cellstr(current(valid));
    if isempty(selected)
        lb.Value = names;
    else
        lb.Value = selected;
    end
end
