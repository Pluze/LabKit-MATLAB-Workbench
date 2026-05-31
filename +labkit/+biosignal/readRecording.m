function [recording, status] = readRecording(filepath, opts)
%READRECORDING Read a biosignal file into a standard recording struct.

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
