% Private DTA helper. Expected caller: labkit.dta facade and internal parser,
% session, pulse, or item pipeline. Inputs and outputs use internal structs,
% tables, file paths, or numeric vectors. Side effects: file discovery/parser reads
% only where named; assumes app-specific workflow decisions stay outside +labkit.
function [session, report] = removeSelectedSessionItems(session, selectedNames, callbacks)
%REMOVESELECTEDSESSIONITEMS Remove session items selected by display name.
%
% Called by:
%   labkit.dta.removeSelectedItemsFromSession
%
% Inputs:
%   session - labkit_session struct.
%   selectedNames - char/string/cell/string array of item display names.
%   callbacks - optional struct with onRemoved(name,item).
%
% Outputs:
%   session - updated session.
%   report - struct with removed and missing cell arrays.
%
% Notes:
%   Empty selections are no-ops. Callback execution happens before the lower
%   level removal so apps can log the original item.

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

    [session, report] = removeFilesFromSession(session, removeNames);
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
        error('labkit:dta:InvalidSelectedNames', ...
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
