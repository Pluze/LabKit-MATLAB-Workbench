function varargout = setListSelection(ui, id, items, preferred, opts)
%SETLISTSELECTION Apply list selection for a UI 2.0 list-bearing control.
%
% App-facing contract:
%   [value, index] = labkit.ui.view.setListSelection(ui, id, items, preferred, opts)
%
% Inputs:
%   ui - UI registry returned by labkit.ui.app.create.
%   id - semantic id for a pathPanel or list-bearing control.
%   items - display item list.
%   preferred - preferred selected item, items, or index.
%   opts - optional selection policy struct.
%
% Outputs:
%   value - applied listbox value.
%   index - applied selection indices.

    if nargin < 4
        preferred = [];
    end
    if nargin < 5
        opts = struct();
    end
    control = resolveControl(ui, id);
    if ~isfield(control, 'listbox') || ~isgraphics(control.listbox)
        error('labkit:ui:view:NoListbox', ...
            'Control "%s" does not expose a listbox.', control.id);
    end
    [value, index] = labkit.ui.view.update( ...
        control.listbox, 'listSelection', items, preferred, opts);
    if nargout >= 1
        varargout{1} = value;
    end
    if nargout >= 2
        varargout{2} = index;
    end
end
