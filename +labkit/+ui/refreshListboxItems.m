function refreshListboxItems(lb, names)
%REFRESHLISTBOXITEMS Refresh a multiselect listbox and preserve valid picks.

    labkit.ui.refreshListboxSelection(lb, names, lb.Value, struct('defaultSelection', 'all'));
end
