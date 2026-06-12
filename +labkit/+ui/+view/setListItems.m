function setListItems(ui, id, items)
%SETLISTITEMS Replace the items of a UI 2.0 list-bearing control.
%
% App-facing contract:
%   labkit.ui.view.setListItems(ui, id, items)
%
% Inputs:
%   ui - UI registry returned by labkit.ui.app.create.
%   id - semantic id for a pathPanel or list-bearing control.
%   items - cell array or string array of display names.
%
% Output:
%   None.

    control = resolveControl(ui, id);
    listbox = listboxHandle(control);
    labkit.ui.view.update(listbox, 'listItems', items);
end

function listbox = listboxHandle(control)
    if isfield(control, 'listbox') && isgraphics(control.listbox)
        listbox = control.listbox;
        return;
    end
    error('labkit:ui:view:NoListbox', ...
        'Control "%s" does not expose a listbox.', control.id);
end
