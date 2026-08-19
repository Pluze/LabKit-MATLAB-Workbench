function [recording, status] = readRecording(filepath, opts)
%READRECORDING Read a biosignal file into a standard recording struct.
%
% Usage:
%   [recording, status] = labkit.biosignal.readRecording(filepath)
%   [recording, status] = labkit.biosignal.readRecording(filepath, opts)
%
% Description:
%   Imports supported biosignal files into one recording format used by the
%   rest of labkit.biosignal. MAT files contribute each numeric or logical
%   vector stored in a timetable or table, the channels in a BIOPAC
%   AcqKnowledge export containing data, isi, isi_units, labels, and units
%   variables, or one unambiguous nonscalar numeric array.
%   CSV, TSV, and TXT files contribute each selected numeric column other
%   than the time column.
%
%   For delimited text, the importer detects a header after an optional
%   preamble and recognizes numeric, datetime, or duration time columns.
%   BIOPAC text preambles also supply channel labels and units when present. An
%   explicit timeColumn takes precedence. Otherwise, names that look like
%   time are preferred; a headerless first numeric column and the common I0
%   device column are also recognized. If no time column can be identified,
%   the importer creates a sample-index time axis. All returned signal times
%   are measured in seconds from zero. By default, decoded channels are
%   normalized to a uniform time grid using the median positive sample
%   interval. Non-finite time rows are removed, samples are time-sorted, and
%   duplicate times retain their first sample. Linear interpolation is limited
%   to contiguous sections; gaps larger than gapFactor are compressed between
%   sections rather than bridged.
%
%   Import and format errors are reported in status instead of being thrown.
%   The returned recording is then an empty recording carrying the requested
%   source path. An invalid filepath value is a programming error and is
%   thrown before import begins.
%
%   Internally, lightweight file facts rank compatible parsers. If the first
%   candidate rejects the content, the importer tries the next compatible
%   candidate without changing this public call. The selected format, file
%   facts, and attempts are returned as import metadata.
%
% Inputs:
%   filepath - Character vector or scalar string naming a MAT, CSV, TSV, or
%              TXT file.
%   opts - Optional scalar struct containing the fields listed below.
%
% Options:
%   headerLine - Positive integer giving the header line, or the first data
%                line when hasHeader is false. By default the importer scans
%                the first 120 lines.
%   hasHeader - Logical scalar indicating whether headerLine contains column
%               names. The default [] selects automatic detection.
%   timeColumn - Column name or 1-based column index to use as time. The
%                default [] enables the inference described above.
%   timeUnit - Unit for a numeric time column: "seconds", "milliseconds",
%              "microseconds", "nanoseconds", or the abbreviations s, sec,
%              ms, us, and ns. "sample", "samples", "index", and
%              "sample_index" leave the numeric scale unchanged. The
%              default infers SI-prefixed units from the column name and
%              otherwise uses seconds.
%   signalColumns - Column names or 1-based indices to import from a
%                   delimited file. The default [] imports every numeric
%                   non-time vector.
%   fallbackFs - Positive sample rate in hertz. It sets the spacing of a
%                synthetic time axis and supplies a nominal interval when
%                timestamps cannot provide one. Without it, synthetic
%                sample-index time advances by one second per row.
%   timeRepair - "auto" (default) replaces duplicate or backward timestamp
%                steps with the nominal positive step. "none" and "off"
%                preserve the converted intervals after shifting to zero.
%   gapFactor - Positive scalar used to identify unusually large positive
%               gaps. A gap larger than gapFactor times the median positive
%               interval is reported and separates uniform-resampling
%               sections. The default is 20.
%   useFirstNumericColumnAsTime - Logical scalar. true permits the first
%                                 numeric column to be used when no other
%                                 time rule matches. The default is false.
%   resampleUniform - Logical scalar. true (default) cleans every decoded
%                     channel onto a uniform seconds grid. false preserves
%                     the parser-produced time axis.
%
% Outputs:
%   recording - Scalar recording structure. signals is a structure array
%               with one element per imported channel.
%   status - Scalar structure describing whether import succeeded.
%
% Recording Fields:
%   type - String scalar "biosignalRecording".
%   version - Recording schema version, currently 1.
%   sourcePath - Source path supplied by filepath.
%   name - Source file name including its extension.
%   signals - Channel structures with time, values, fs, name, displayName,
%             sourceName, unit, and metadata fields.
%   metadata - Import information. Text imports report sourceKind,
%              timeColumn, timeUnit, timeSource, timeRepair,
%              importHeaderLine, and importHasHeader. BIOPAC signal metadata
%              records its source format and sample-interval provenance. All
%              successful imports add detectedFormat, importFallbackUsed,
%              importAttempts, fileInfo, and samplingNormalization.
%
% Status Fields:
%   ok - Logical true when import completed.
%   message - Empty string on success; otherwise the import error message.
%   kind - "mat" or "table" on success. Failed requests report "unknown"
%          or the attempted file extension.
%   filepath - Normalized source path.
%   format - Selected content format, such as "biopac_mat",
%            "timetable_mat", "table_mat", "numeric_mat",
%            "biopac_text", or "delimited_text".
%   fallbackUsed - Logical true when an earlier compatible parser failed.
%   attempts - Structure array with format, ok, and message fields.
%   fileInfo - Structure with extension, byte count, lightweight detected
%              format, and the resolved format when import succeeds.
%
% Failure Behavior:
%   A missing, unsupported, unreadable, or malformed source, including a
%   malformed BIOPAC export signature, returns
%   status.ok=false, preserves the normalized source path, and returns an
%   empty recording. Only an invalid filepath MATLAB value is thrown as
%   labkit:biosignal:InvalidFilepath before import begins.
%   Unknown option fields or a non-struct opts value throw
%   labkit:biosignal:InvalidOptions.
%
% Example:
%   filepath = [tempname '.csv'];
%   sampleTime = (0:0.01:0.03)';
%   ECG = [0; 1; 0; -1];
%   writetable(table(sampleTime, ECG), filepath);
%   cleanup = onCleanup(@() delete(filepath));
%   [recording, status] = labkit.biosignal.readRecording(filepath, ...
%       struct('timeColumn', 'sampleTime', 'timeUnit', 'seconds'));
%   signal = labkit.biosignal.getChannel(recording, 'ECG');
%
% See also labkit.biosignal.listChannels,
%   labkit.biosignal.getChannel

    if nargin < 2
        opts = struct();
    end
    validateOptionStruct(opts, ["headerLine", "hasHeader", "timeColumn", ...
        "timeUnit", "signalColumns", "fallbackFs", "timeRepair", ...
        "gapFactor", "useFirstNumericColumnAsTime", "resampleUniform"]);

    filepath = normalizeFilepath(filepath);
    recording = emptyRecording(filepath);
    fileInfo = basicFileInfo(filepath);
    attempts = emptyAttempts();
    status = makeStatus(filepath, false, "unknown", "unknown", "", ...
        false, attempts, fileInfo);

    if exist(filepath, 'file') ~= 2
        status.message = "File not found.";
        return;
    end

    try
        [plan, fileInfo] = recordingImportPlan(filepath);
    catch ME
        status = makeStatus(filepath, false, fileInfo.extension, ...
            fileInfo.detectedFormat, string(ME.message), false, attempts, fileInfo);
        return;
    end

    attempts = repmat(makeAttempt("", false, ""), numel(plan), 1);
    attemptCount = 0;

    for k = 1:numel(plan)
        try
            candidateRecording = plan(k).reader(filepath, opts);
        catch ME
            attemptCount = attemptCount + 1;
            attempts(attemptCount) = makeAttempt( ...
                plan(k).format, false, string(ME.message));
            continue;
        end

        resolvedFormat = resolveFormat(plan(k).format, candidateRecording);
        attemptCount = attemptCount + 1;
        attempts(attemptCount) = makeAttempt(resolvedFormat, true, "");
        completedAttempts = attempts(1:attemptCount);
        try
            candidateRecording = normalizeRecordingSampling(candidateRecording, opts);
        catch ME
            status = makeStatus(filepath, false, plan(k).kind, resolvedFormat, ...
                string(ME.message), k > 1, completedAttempts, fileInfo);
            return;
        end
        fileInfo.resolvedFormat = resolvedFormat;
        candidateRecording.metadata.detectedFormat = resolvedFormat;
        candidateRecording.metadata.importFallbackUsed = k > 1;
        candidateRecording.metadata.importAttempts = completedAttempts;
        candidateRecording.metadata.fileInfo = fileInfo;
        recording = candidateRecording;
        status = makeStatus(filepath, true, plan(k).kind, resolvedFormat, ...
            "", k > 1, completedAttempts, fileInfo);
        return;
    end

    messages = string({attempts.message});
    messages = messages(strlength(messages) > 0);
    attempts = attempts(1:attemptCount);
    status = makeStatus(filepath, false, fileInfo.extension, ...
        fileInfo.detectedFormat, strjoin(messages, " | "), ...
        numel(attempts) > 1, attempts, fileInfo);
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

function fileInfo = basicFileInfo(filepath)
    [~, ~, extension] = fileparts(filepath);
    fileInfo = struct( ...
        'extension', lower(string(extension)), ...
        'bytes', NaN, ...
        'detectedFormat', "unknown", ...
        'resolvedFormat', "unknown");
end

function format = resolveFormat(plannedFormat, recording)
    format = string(plannedFormat);
    if format == "delimited_text" && isfield(recording.metadata, 'sourceKind') && ...
            recording.metadata.sourceKind == "biopac_text"
        format = "biopac_text";
    end
end

function attempts = emptyAttempts()
    attempts = struct('format', {}, 'ok', {}, 'message', {});
end

function attempt = makeAttempt(format, ok, message)
    attempt = struct( ...
        'format', string(format), ...
        'ok', logical(ok), ...
        'message', string(message));
end

function status = makeStatus(filepath, ok, kind, format, message, fallbackUsed, attempts, fileInfo)
    status = struct( ...
        'ok', ok, ...
        'message', string(message), ...
        'kind', string(kind), ...
        'filepath', filepath, ...
        'format', string(format), ...
        'fallbackUsed', logical(fallbackUsed), ...
        'attempts', attempts, ...
        'fileInfo', fileInfo);
end
