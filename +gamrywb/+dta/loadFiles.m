function [items, report] = loadFiles(filepaths, expectedKind, opts)
%LOADFILES Load multiple supported DTA files without GUI side effects.

    if nargin < 2
        expectedKind = "auto";
    end
    if nargin < 3
        opts = struct();
    end

    expectedKind = gamrywb.dta.normalizeExpectedKind(expectedKind);
    filepaths = normalizeFilepaths(filepaths);
    items = {};
    report = emptyReport();

    for k = 1:numel(filepaths)
        [item, status] = gamrywb.dta.loadFile(filepaths{k}, expectedKind, opts);
        report.statuses(end+1) = status; %#ok<AGROW>

        if status.ok
            items{end+1} = item; %#ok<AGROW>
            report.loaded{end+1} = status.filepath; %#ok<AGROW>
        else
            report.failed(end+1) = struct( ...
                'filepath', status.filepath, ...
                'kind', status.kind, ...
                'message', status.message); %#ok<AGROW>
        end
    end

    report.nRequested = numel(filepaths);
    report.nLoaded = numel(report.loaded);
    report.nFailed = numel(report.failed);
end

function filepaths = normalizeFilepaths(filepaths)
    if isempty(filepaths)
        filepaths = {};
        return;
    end

    if ischar(filepaths) || (isstring(filepaths) && isscalar(filepaths))
        filepaths = {char(filepaths)};
        return;
    end

    if isstring(filepaths)
        filepaths = cellstr(filepaths(:));
        return;
    end

    if iscell(filepaths)
        filepaths = filepaths(:).';
        for k = 1:numel(filepaths)
            if ~(ischar(filepaths{k}) || (isstring(filepaths{k}) && isscalar(filepaths{k})))
                error('gamrywb:dta:InvalidFilepath', 'Each filepath must be a character vector or scalar string.');
            end
            filepaths{k} = char(filepaths{k});
        end
        return;
    end

    error('gamrywb:dta:InvalidFilepaths', 'Filepaths must be a path, string array, or cell array of paths.');
end

function report = emptyReport()
    report = struct();
    report.loaded = {};
    report.failed = struct('filepath', {}, 'kind', {}, 'message', {});
    report.statuses = struct( ...
        'ok', {}, ...
        'message', {}, ...
        'kind', {}, ...
        'expectedKind', {}, ...
        'filepath', {});
    report.nRequested = 0;
    report.nLoaded = 0;
    report.nFailed = 0;
end
