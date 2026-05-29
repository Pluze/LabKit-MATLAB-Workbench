function refreshFileListbox(lb, items)
%REFRESHFILELISTBOX Refresh a file listbox from session items by display name.

    if isempty(items)
        gamrywb.ui.refreshListboxItems(lb, {});
        return;
    end

    names = {items.name};
    gamrywb.ui.refreshListboxItems(lb, names);
end
