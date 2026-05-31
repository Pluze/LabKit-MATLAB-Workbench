function [recording, status] = readRecording(filepath, opts)
%READRECORDING Read a biosignal file into a standard recording struct.
%
% Usage:
%   [recording, status] = labkit.biosignal.readRecording(filepath);
%   opts = struct('timeColumn', 'timestamp', 'timeUnit', 'milliseconds');
%   [recording, status] = labkit.biosignal.readRecording(filepath, opts);
%
% Inputs:
%   filepath - char/string path to a MAT, CSV, TSV, or TXT recording file.
%   opts - optional struct for delimited text and MAT timetable import.
%
% Options:
%   headerLine - positive integer header/data start line for CSV/TSV/TXT.
%   hasHeader - logical scalar; []/missing means auto-detect.
%   timeColumn - column name or 1-based index to use as time.
%   timeUnit - "seconds", "milliseconds", "microseconds", "nanoseconds",
%              or sample/index aliases. Missing means infer from name.
%   signalColumns - names or 1-based indices to import as signal channels.
%   fallbackFs - positive scalar Hz for synthetic time or timestamp repair.
%   timeRepair - "auto" (default) to stitch backward/duplicate timestamps,
%                or "none"/"off" to leave converted relative time.
%   gapFactor - positive scalar, default 20; flags large positive gaps.
%   useFirstNumericColumnAsTime - logical, default false; opt-in fallback
%                                 for ambiguous tables.
%
% Output:
%   recording - struct with sourcePath, name, signals, and metadata.
%   status - struct with ok, message, kind, and filepath. Failed imports do
%            not throw unless filepath itself is invalid.

    if nargin < 2
        opts = struct();
    end

    filepath = normalizeFilepath(filepath);
    recording = emptyRecording(filepath);
    status = makeStatus(filepath, false, "unknown", "");

    if exist(filepath, 'file') ~= 2
        status.message = "File not found.";
        return;
    end

    [~, ~, ext] = fileparts(filepath);
    ext = lower(string(ext));

    try
        switch ext
            case ".mat"
                recording = readMatRecording(filepath, opts);
                kind = "mat";
            case {".csv", ".txt", ".tsv"}
                recording = readCsvRecording(filepath, opts);
                kind = "table";
            otherwise
                error('labkit:biosignal:UnsupportedFile', ...
                    'Unsupported biosignal file extension: %s.', ext);
        end

        status = makeStatus(filepath, true, kind, "");
    catch ME
        status = makeStatus(filepath, false, ext, string(ME.message));
    end
end

function filepath = normalizeFilepath(filepath)
    if ~(ischar(filepath) || (isstring(filepath) && isscalar(filepath)))
        error('labkit:biosignal:InvalidFilepath', ...
            'Filepath must be a character vector or scalar string.');
    end
    filepath = char(filepath);
end

function recording = emptyRecording(filepath)
    [~, name, ext] = fileparts(filepath);
    recording = struct( ...
        'type', "biosignalRecording", ...
        'version', 1, ...
        'sourcePath', filepath, ...
        'name', string([name ext]), ...
        'signals', struct([]), ...
        'metadata', struct());
end

function status = makeStatus(filepath, ok, kind, message)
    status = struct( ...
        'ok', ok, ...
        'message', string(message), ...
        'kind', string(kind), ...
        'filepath', filepath);
end
