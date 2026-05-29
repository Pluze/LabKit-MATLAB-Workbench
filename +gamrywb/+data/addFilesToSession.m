function [session, report] = addFilesToSession(session, filepaths, loader)
%ADDFILESTOSESSION Add files to a session using a caller-provided loader.

    if nargin < 3 || isempty(loader)
        loader = @defaultLoader;
    end

    filepaths = normalizeFilepaths(filepaths);
    report = struct();
    report.added = {};
    report.skipped = {};
    report.failed = struct('filepath', {}, 'message', {});

    for k = 1:numel(filepaths)
        filepath = filepaths{k};
        if hasFilepath(session.items, filepath)
            report.skipped{end+1} = filepath; %#ok<AGROW>
            continue;
        end

        try
            item = loader(filepath);
            if ~isfield(item, 'filepath') || isempty(item.filepath)
                item.filepath = filepath;
            end
            if ~isfield(item, 'name') || isempty(item.name)
                item.name = gamrywb.util.shortName(filepath);
            end
            session.items = gamrywb.util.appendStruct(session.items, item);
            report.added{end+1} = filepath; %#ok<AGROW>
        catch ME
            report.failed(end+1) = struct('filepath', filepath, 'message', ME.message); %#ok<AGROW>
        end
    end

    session.modifiedAt = datestr(now, 'yyyy-mm-ddTHH:MM:SS');
end

function item = defaultLoader(filepath)
    item = struct();
    item.filepath = filepath;
    item.name = gamrywb.util.shortName(filepath);
end

function tf = hasFilepath(items, filepath)
    tf = false;
    if isempty(items) || ~isfield(items, 'filepath')
        return;
    end
    tf = any(strcmp(string({items.filepath}), string(filepath)));
end

function out = normalizeFilepaths(filepaths)
    if ischar(filepaths)
        out = {filepaths};
    elseif isstring(filepaths)
        out = cellstr(filepaths(:));
    elseif iscell(filepaths)
        out = filepaths(:).';
    else
        error('filepaths must be a char, string, or cell array.');
    end
end
