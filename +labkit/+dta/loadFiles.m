function [items, report] = loadFiles(filepaths, expectedKind, opts)
%LOADFILES Read a list of Gamry DTA files.
%
% Usage:
%   [items, report] = labkit.dta.loadFiles(filepaths)
%   [items, report] = labkit.dta.loadFiles(filepaths, expectedKind)
%   [items, report] = labkit.dta.loadFiles(filepaths, expectedKind, opts)
%
% Description:
%   Calls loadFile for each path in input order. Successful items are returned
%   in items; failures do not stop the batch and are recorded in report. The
%   positions in items therefore need not match the positions in filepaths;
%   use report.statuses when per-input correspondence matters.
%
% Inputs:
%   filepaths - One character-vector or string-scalar path, a string array, or
%       a cell array of character vectors and string scalars. An empty input is
%       allowed and returns an empty report.
%   expectedKind - "auto", "chrono", "eis", or "cvct", with the same
%       normalization as loadFile. Default: "auto".
%   opts - Optional scalar structure forwarded unchanged to loadFile.
%
% Options:
%   pulseMode - Pulse-detection mode used for chrono files. See detectPulses
%       for the legal labels and normalization behavior.
%   pulseOptions - Scalar structure accepted by detectPulses. When both
%       pulseOptions and pulseMode are present, pulseOptions takes precedence.
%
% Outputs:
%   items - Cell row vector containing successfully loaded item structures in
%       input order, with failed inputs omitted.
%   report - Scalar structure summarizing every requested path.
%
% Output Fields:
%   loaded - Cell array of paths that loaded successfully.
%   failed - Structure array with filepath, kind, and message for failures.
%   statuses - One loadFile status structure per requested input, in input
%       order.
%   nRequested - Number of input paths.
%   nLoaded - Number of successful items.
%   nFailed - Number of failed inputs.
%
% Errors:
%   Throws labkit:dta:InvalidFilepaths or labkit:dta:InvalidFilepath when the
%   path collection contains unsupported values, and labkit:dta:InvalidKind
%   for an unsupported expectedKind. Individual file read failures are stored
%   in report instead of thrown.
%
% Example:
%   files = ["run-01.DTA", "run-02.DTA"];
%   [items, report] = labkit.dta.loadFiles(files, "chrono");
%   fprintf("Loaded %d of %d files.\n", report.nLoaded, report.nRequested)

    if nargin < 2
        expectedKind = "auto";
    end
    if nargin < 3
        opts = struct();
    end

    expectedKind = normalizeExpectedKind(expectedKind);
    filepaths = normalizeFilepaths(filepaths);
    items = {};
    report = emptyReport();

    for k = 1:numel(filepaths)
        [item, status] = labkit.dta.loadFile(filepaths{k}, expectedKind, opts);
        report.statuses(end+1) = status;

        if status.ok
            items{end+1} = item;
            report.loaded{end+1} = status.filepath;
        else
            report.failed(end+1) = struct( ...
                'filepath', status.filepath, ...
                'kind', status.kind, ...
                'message', status.message);
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
                error('labkit:dta:InvalidFilepath', 'Each filepath must be a character vector or scalar string.');
            end
            filepaths{k} = char(filepaths{k});
        end
        return;
    end

    error('labkit:dta:InvalidFilepaths', 'Filepaths must be a path, string array, or cell array of paths.');
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
