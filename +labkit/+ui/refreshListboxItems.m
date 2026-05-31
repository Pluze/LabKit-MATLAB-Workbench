function refreshListboxItems(lb, names)
%REFRESHLISTBOXITEMS Refresh a multiselect listbox and preserve valid picks.
%
% Inputs:
%   lb - MATLAB listbox handle.
%   names - char/string/cellstr item names.
%
% Output:
%   Mutates lb.Items and lb.Value in place, defaulting to all items.

    labkit.ui.refreshListboxSelection(lb, names, lb.Value, struct('defaultSelection', 'all'));
end
