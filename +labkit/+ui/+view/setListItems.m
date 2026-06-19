function setListItems(ui, id, items)
%SETLISTITEMS Replace the items of a UI 2.0 list-bearing control.
%
% App-facing contract:
%   labkit.ui.view.setListItems(ui, id, items)
%
% Inputs:
%   ui - UI registry returned by labkit.ui.app.create.
%   id - semantic id for a pathPanel or list-bearing control.
%   items - cell array or string array of display names. For pathPanel
%       controls, empty items restore the framework empty prompt instead of
%       leaving the listbox visually blank.
%
% Output:
%   None.

    control = resolveControl(ui, id);
    if isPathPanel(control) && isEmptyItemSet(items)
        control.setValue({});
        return;
    end
    listbox = listboxHandle(control);
    refreshListboxItems(listbox, items);
end

function tf = isPathPanel(control)
    tf = isfield(control, 'kind') && strcmp(control.kind, 'pathPanel') && ...
        isfield(control, 'setValue') && isa(control.setValue, 'function_handle');
end

function tf = isEmptyItemSet(items)
    tf = isempty(items);
    if tf
        return;
    end
    text = string(items);
    tf = all(strlength(text) == 0);
end

function listbox = listboxHandle(control)
    if isfield(control, 'listbox') && isgraphics(control.listbox)
        listbox = control.listbox;
        return;
    end
    error('labkit:ui:view:NoListbox', ...
        'Control "%s" does not expose a listbox.', control.id);
end
