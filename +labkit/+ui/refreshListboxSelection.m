function [value, index] = refreshListboxSelection(lb, names, preferredSelection, opts)
%REFRESHLISTBOXSELECTION Refresh listbox items while preserving valid selection.
%
% Usage:
%   [value, idx] = labkit.ui.refreshListboxSelection(lb, names, oldValue);
%   [value, idx] = labkit.ui.refreshListboxSelection(lb, names, [], ...
%       struct('defaultSelection', 'all'));
%
% Inputs:
%   lb - MATLAB listbox handle.
%   names - char/string/cellstr listbox items.
%   preferredSelection - optional previous value, item names, or indices.
%   opts - optional struct.
%
% Options:
%   defaultSelection - "first" (default) or "all" for multiselect listboxes.
%
% Output:
%   value - selected listbox value after refresh.
%   index - numeric selected indices in names.

    if nargin < 3
        preferredSelection = lb.Value;
    end
    if nargin < 4
        opts = struct();
    end

    if isempty(names)
        lb.Items = {};
        lb.Value = {};
        value = {};
        index = [];
        return;
    end

    names = normalizeNames(names);
    lb.Items = names;

    selected = selectValidNames(names, preferredSelection);
    if isempty(selected)
        selected = defaultSelection(names, lb, opts);
    end

    if isMultiselect(lb)
        value = selected;
    else
        value = selected{1};
    end
    lb.Value = value;
    index = selectedIndexes(names, selected);
end

function names = normalizeNames(names)
    if isstring(names)
        names = cellstr(names);
    elseif ischar(names)
        names = {names};
    end
    names = reshape(names, 1, []);
end

function selected = selectValidNames(names, preferredSelection)
    selected = {};
    if isempty(preferredSelection)
        return;
    end

    if isnumeric(preferredSelection)
        idx = preferredSelection(preferredSelection >= 1 & preferredSelection <= numel(names));
        selected = names(idx);
        return;
    end

    if ischar(preferredSelection) || isstring(preferredSelection)
        preferredSelection = cellstr(string(preferredSelection));
    end
    preferredSelection = reshape(preferredSelection, 1, []);
    keep = ismember(string(preferredSelection), string(names));
    selected = cellstr(string(preferredSelection(keep)));
end

function selected = defaultSelection(names, lb, opts)
    defaultMode = optionValue(opts, 'defaultSelection', 'first');
    if isMultiselect(lb) && strcmp(defaultMode, 'all')
        selected = names;
    else
        selected = names(1);
    end
end

function index = selectedIndexes(names, selected)
    index = [];
    for k = 1:numel(selected)
        idx = find(strcmp(names, selected{k}), 1, 'first');
        if ~isempty(idx)
            index(end+1) = idx; %#ok<AGROW>
        end
    end
end

function tf = isMultiselect(lb)
    tf = isprop(lb, 'Multiselect') && strcmp(lb.Multiselect, 'on');
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isfield(opts, name)
        value = opts.(name);
    end
end
