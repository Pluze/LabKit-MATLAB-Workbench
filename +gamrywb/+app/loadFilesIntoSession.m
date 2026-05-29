function [session, report] = loadFilesIntoSession(session, filepaths, loader, callbacks)
%LOADFILESINTOSESSION Add unique not-yet-loaded files to an app session.

    if nargin < 4
        callbacks = struct();
    end

    report = emptyReport();
    filepaths = normalizeFilepaths(filepaths);
    if isempty(filepaths)
        return;
    end

    filepaths = unique(filepaths, 'stable');
    existing = existingFilepaths(session.items);
    if ~isempty(existing)
        isNew = ~ismember(string(filepaths), existing);
        skipped = filepaths(~isNew);
        filepaths = filepaths(isNew);
        report.skipped = skipped(:).';
        for i = 1:numel(skipped)
            callCallback(callbacks, 'onSkipped', skipped{i});
        end
    end

    if isempty(filepaths)
        return;
    end

    [session, addReport] = gamrywb.data.addFilesToSession(session, filepaths, loader, callbacks);
    report.added = addReport.added;
    report.skipped = [report.skipped addReport.skipped];
    report.failed = addReport.failed;
end

function report = emptyReport()
    report = struct( ...
        'added', {{}}, ...
        'skipped', {{}}, ...
        'failed', {struct('filepath', {}, 'message', {})});
end

function out = normalizeFilepaths(filepaths)
    if isempty(filepaths)
        out = {};
    elseif ischar(filepaths)
        out = {filepaths};
    elseif isstring(filepaths)
        out = cellstr(filepaths(:)).';
    elseif iscell(filepaths)
        out = filepaths(:).';
    else
        error('gamrywb:app:loadFilesIntoSession:InvalidFilepaths', ...
            'filepaths must be a char, string, or cell array.');
    end
end

function existing = existingFilepaths(items)
    existing = strings(0, 1);
    if isempty(items) || ~isfield(items, 'filepath')
        return;
    end
    existing = string({items.filepath});
end

function callCallback(callbacks, name, varargin)
    if isfield(callbacks, name) && isa(callbacks.(name), 'function_handle')
        callbacks.(name)(varargin{:});
    end
end
