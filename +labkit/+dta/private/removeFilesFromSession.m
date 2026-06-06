% Private DTA helper. Expected caller: labkit.dta facade and internal parser,
% session, pulse, or item pipeline. Inputs and outputs use internal structs,
% tables, file paths, or numeric vectors. Side effects: file discovery/parser reads
% only where named; assumes app-specific workflow decisions stay outside +labkit.
function [session, report] = removeFilesFromSession(session, selectors)
%REMOVEFILESFROMSESSION Remove session items by filepath or display name.
%
% Called by:
%   removeSelectedSessionItems and DTA session facade helpers.
%
% Inputs:
%   session - labkit_session struct.
%   selectors - char/string/cell/string array of item filepath or name values.
%
% Outputs:
%   session - session with matching items removed and modifiedAt refreshed.
%   report - struct with removed and missing cell arrays.
%
% Notes:
%   Matching is exact against filepath and name fields. This helper does not
%   call GUI callbacks; higher-level helpers own callback timing.

    selectors = normalizeSelectors(selectors);
    report = struct();
    report.removed = {};
    report.missing = {};

    if isempty(session.items)
        report.missing = selectors;
        session.modifiedAt = datestr(now, 'yyyy-mm-ddTHH:MM:SS');
        return;
    end

    keep = true(1, numel(session.items));
    for k = 1:numel(selectors)
        selector = selectors{k};
        match = false(1, numel(session.items));
        if isfield(session.items, 'filepath')
            match = match | strcmp(string({session.items.filepath}), string(selector));
        end
        if isfield(session.items, 'name')
            match = match | strcmp(string({session.items.name}), string(selector));
        end

        if any(match & keep)
            removedIdx = find(match & keep);
            for ii = removedIdx
                report.removed{end+1} = itemLabel(session.items(ii)); %#ok<AGROW>
            end
            keep(match) = false;
        else
            report.missing{end+1} = selector; %#ok<AGROW>
        end
    end

    session.items = session.items(keep);
    session.modifiedAt = datestr(now, 'yyyy-mm-ddTHH:MM:SS');
end

function label = itemLabel(item)
    if isfield(item, 'filepath') && ~isempty(item.filepath)
        label = item.filepath;
    elseif isfield(item, 'name') && ~isempty(item.name)
        label = item.name;
    else
        label = '';
    end
end

function out = normalizeSelectors(selectors)
    if ischar(selectors)
        out = {selectors};
    elseif isstring(selectors)
        out = cellstr(selectors(:));
    elseif iscell(selectors)
        out = selectors(:).';
    else
        error('labkit:dta:InvalidSessionSelectors', ...
            'selectors must be a char, string, or cell array.');
    end
end
