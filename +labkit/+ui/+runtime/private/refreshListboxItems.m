% Private UI runtime helper. Expected caller: semantic list presentation,
% plot, or text facades. Inputs and outputs are internal UI handles, labels,
% selections, table data, or plot info. Side effects are limited to supplied UI
% parents or axes; assumes the caller owns callbacks and app state.
function refreshListboxItems(lb, names)
%REFRESHLISTBOXITEMS Refresh a multiselect listbox and preserve valid picks.
%
% Inputs:
%   lb - MATLAB listbox handle.
%   names - char/string/cellstr item names.
%
% Output:
%   Mutates lb.Items and lb.Value in place, defaulting to all items.

    refreshListboxSelection(lb, names, lb.Value, struct('defaultSelection', 'all'));
end
