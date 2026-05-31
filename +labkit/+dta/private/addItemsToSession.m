function [session, report] = addItemsToSession(session, filepaths, loader, callbacks)
%ADDITEMSTOSESSION Add files to a session using a caller-provided loader.
%
% Called by:
%   labkit.dta.addFilesToSession
%
% Inputs:
%   session - labkit_session struct with an items field.
%   filepaths - char/string path, string array, or cell array of paths.
%   loader - function handle item = loader(filepath). The loaded item may
%            omit filepath/name; this helper fills them from the source path.
%   callbacks - optional struct with onAdded(filepath,item),
%               onSkipped(filepath), and onFailed(filepath,message).
%
% Output:
%   session - updated session with unique filepaths appended.
%   report - struct with added, skipped, and failed fields.
%
% Notes:
%   Duplicate detection is filepath-based. Loader errors are converted to
%   report.failed rows so GUI apps can show status without catching here.

    if nargin < 3 || isempty(loader)
        loader = @defaultLoader;
    end
    if nargin < 4
        callbacks = struct();
    end

    report = struct();
    report.added = {};
    report.skipped = {};
    report.failed = struct('filepath', {}, 'message', {});

    filepaths = normalizeFilepaths(filepaths);
    if isempty(filepaths)
        return;
    end

    for k = 1:numel(filepaths)
        filepath = filepaths{k};
        if hasFilepath(session.items, filepath)
            report.skipped{end+1} = filepath; %#ok<AGROW>
            callCallback(callbacks, 'onSkipped', filepath);
            continue;
        end

        try
            item = loader(filepath);
            if ~isfield(item, 'filepath') || isempty(item.filepath)
                item.filepath = filepath;
            end
            if ~isfield(item, 'name') || isempty(item.name)
                item.name = shortName(filepath);
            end
            session.items = appendStruct(session.items, item);
            report.added{end+1} = filepath; %#ok<AGROW>
            callCallback(callbacks, 'onAdded', filepath, item);
        catch ME
            report.failed(end+1) = struct('filepath', filepath, 'message', ME.message); %#ok<AGROW>
            callCallback(callbacks, 'onFailed', filepath, ME.message);
        end
    end

    session.modifiedAt = datestr(now, 'yyyy-mm-ddTHH:MM:SS');
end

function item = defaultLoader(filepath)
    item = struct();
    item.filepath = filepath;
    item.name = shortName(filepath);
end

function out = appendStruct(S, item)
    if isempty(S)
        out = item;
    else
        out = [S, item];
    end
end

function name = shortName(filepath)
    [~, name, ext] = fileparts(filepath);
    name = [name ext];
end

function tf = hasFilepath(items, filepath)
    tf = false;
    if isempty(items) || ~isfield(items, 'filepath')
        return;
    end
    tf = any(strcmp(string({items.filepath}), string(filepath)));
end

function out = normalizeFilepaths(filepaths)
    if isempty(filepaths)
        out = {};
    elseif ischar(filepaths)
        out = {filepaths};
    elseif isstring(filepaths)
        out = cellstr(filepaths(:));
    elseif iscell(filepaths)
        out = filepaths(:).';
    else
        error('labkit:dta:InvalidFilepaths', 'filepaths must be a char, string, or cell array.');
    end
end

function callCallback(callbacks, name, varargin)
    if isfield(callbacks, name) && isa(callbacks.(name), 'function_handle')
        callbacks.(name)(varargin{:});
    end
end
