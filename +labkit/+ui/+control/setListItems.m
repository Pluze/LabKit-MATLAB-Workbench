function setListItems(ui, id, items)
%SETLISTITEMS Replace the items of a UI 5 list-bearing control.
%
% App-facing contract:
%   labkit.ui.control.setListItems(ui, id, items)
%
% Inputs:
%   ui - UI registry returned by labkit.ui.runtime.create.
%   id - semantic id for a list-bearing control.
%   items - cell array or string array of display names. For filePanel
%       controls, only empty items are accepted; use setValue to replace
%       file entries and setFileSelection to select entries.
%
% Output:
%   None.

    control = resolveControl(ui, id);
    if isResettablePanel(control) && isEmptyItemSet(items)
        control.setValue({});
        return;
    end
    if isFilePanel(control)
        error('labkit:ui:control:FilePanelListItems', ...
            ['filePanel items are file-entry structs, not display labels; ' ...
            'use setValue to replace file entries.']);
    end
    listbox = listboxHandle(control);
    refreshListboxItems(listbox, items);
end

function tf = isResettablePanel(control)
    tf = isFilePanel(control) && ...
        isfield(control, 'setValue') && isa(control.setValue, 'function_handle');
end

function tf = isFilePanel(control)
    tf = isfield(control, 'kind') && strcmp(control.kind, 'filePanel');
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
    error('labkit:ui:control:NoListbox', ...
        'Control "%s" does not expose a listbox.', control.id);
end
