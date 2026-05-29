function [session, report] = removeSelectedItemsFromSession(session, selectedNames, callbacks)
%REMOVESELECTEDITEMSFROMSESSION Remove session items by selected display names.

    if nargin < 3
        callbacks = struct();
    end

    report = emptyReport();
    selectedNames = normalizeSelectedNames(selectedNames);
    if isempty(session.items) || isempty(selectedNames)
        return;
    end

    removeNames = {};
    for i = 1:numel(session.items)
        itemName = itemDisplayName(session.items(i));
        if any(selectedNames == string(itemName))
            removeNames{end+1} = itemName; %#ok<AGROW>
            callCallback(callbacks, 'onRemoved', itemName, session.items(i));
        end
    end

    [session, report] = gamrywb.data.removeFilesFromSession(session, removeNames);
end

function report = emptyReport()
    report = struct( ...
        'removed', {{}}, ...
        'missing', {{}});
end

function names = normalizeSelectedNames(selectedNames)
    if isempty(selectedNames)
        names = strings(0, 1);
    elseif ischar(selectedNames)
        names = string({selectedNames});
    elseif isstring(selectedNames)
        names = selectedNames(:);
    elseif iscell(selectedNames)
        names = string(selectedNames(:));
    else
        error('gamrywb:ui:removeSelectedItemsFromSession:InvalidSelectedNames', ...
            'selectedNames must be a char, string, or cell array.');
    end
end

function name = itemDisplayName(item)
    if isfield(item, 'name') && ~isempty(item.name)
        name = item.name;
    else
        name = '';
    end
end

function callCallback(callbacks, name, varargin)
    if isfield(callbacks, name) && isa(callbacks.(name), 'function_handle')
        callbacks.(name)(varargin{:});
    end
end
