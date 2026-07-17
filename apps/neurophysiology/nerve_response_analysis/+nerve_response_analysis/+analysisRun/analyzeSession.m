function analysis = analyzeSession(session, protocol, opts)
%ANALYZESESSION Analyze accepted RHS recordings and combine their results.
%
% Usage:
%   analysis = nerve_response_analysis.analysisRun.analyzeSession(session)
%   analysis = nerve_response_analysis.analysisRun.analyzeSession( ...
%       session, protocol)
%   analysis = nerve_response_analysis.analysisRun.analyzeSession( ...
%       session, protocol, opts)
%
% Description:
%   Selects accepted rows from an RHS Preview filter record, analyzes each file
%   with analyzeRecording, and vertically concatenates event, train, metric,
%   and issue tables. A failure in one recording becomes an issue row and does
%   not stop later recordings.
%
% Inputs:
%   session - Scalar structure whose recordings field is a table or structure
%       array. Required recording columns are recordingId and filePath. label,
%       comment, qcFlag, and keep are optional selection/provenance fields.
%   protocol - Optional channel-role and pair protocol passed unchanged to each
%       recording. See analyzeRecording. Default: struct().
%   opts - Optional scalar structure. Recording-level fields are forwarded to
%       analyzeRecording after recordingId is replaced by the current row id.
%
% Recording Selection:
%   If keep exists, rows with logical keep=true are selected. Otherwise label
%   selects normalized "good" rows; accepted synonyms are good, keep, kept,
%   true, 1, yes, and y, while bad/reject synonyms normalize to "bad". If label
%   is absent but qcFlag exists, rows equal to "accepted" are selected. With no
%   selection column, every row is treated as good. This precedence means keep
%   overrides label and qcFlag when more than one is present.
%
% Options:
%   maxRecordings - Positive finite limit applied after recording selection.
%       Zero, nonpositive, nonfinite, or omitted input means no limit. Default:
%       Inf.
%   maxDurationSec - Forwarded to analyzeRecording for every selected file.
%   eventDetection - Forwarded to analyzeRecording for every selected file.
%
% Outputs:
%   analysis - Scalar session-analysis structure.
%
% Analysis Fields:
%   type, version - "nerveResponseSessionAnalysis" and schema version 1.
%   recordingCount - Total rows before acceptance filtering.
%   analyzedCount - Number of selected rows after maxRecordings. This counts
%       attempted recordings, including files that later produce issues.
%   protocolSnapshot - Protocol supplied by the caller.
%   events, trains, metrics - Combined nonempty tables returned by recording
%       analyses.
%   issues - Combined recording issues plus caught exceptions, with recordingId,
%       severity, and message columns.
%
% Failure Behavior:
%   A recording-level analysis exception is converted to one issue row and
%   later recordings continue. Missing or unsupported session.recordings input
%   becomes an empty session; a nonempty table without recordingId or filePath,
%   incompatible selection columns, or unappendable result tables may still
%   raise the originating table/field error before or between recordings.
%
% Example:
%   recordings = table(strings(0,1), strings(0,1), ...
%       'VariableNames', {'recordingId', 'filePath'});
%   session = struct("recordings", recordings);
%   analysis = nerve_response_analysis.analysisRun.analyzeSession(session);
%   assert(analysis.recordingCount == 0 && analysis.analyzedCount == 0)
%
% See also nerve_response_analysis.analysisRun.analyzeRecording,
%   nerve_response_analysis.analysisRun.detectEventTrains,
%   nerve_response_analysis.analysisRun.measureCapMetrics

    if nargin < 2 || isempty(protocol)
        protocol = struct();
    end
    if nargin < 3 || isempty(opts)
        opts = struct();
    end

    recordings = recordingsTable(session);
    accepted = acceptedRows(recordings);

    maxRecordings = double(fieldOrDefault(opts, "maxRecordings", Inf));
    if isfinite(maxRecordings) && maxRecordings > 0
        accepted = accepted(1:min(height(accepted), maxRecordings), :);
    end

    analysis = struct( ...
        "type", "nerveResponseSessionAnalysis", ...
        "version", 1, ...
        "recordingCount", height(recordings), ...
        "analyzedCount", height(accepted), ...
        "protocolSnapshot", protocol, ...
        "events", table(), ...
        "trains", table(), ...
        "metrics", table(), ...
        "issues", emptyIssues());

    for k = 1:height(accepted)
        recordingOpts = opts;
        recordingOpts.recordingId = string(accepted.recordingId(k));
        try
            item = nerve_response_analysis.analysisRun.analyzeRecording( ...
                accepted.filePath(k), protocol, recordingOpts);
            analysis.events = appendTable(analysis.events, item.events);
            analysis.trains = appendTable(analysis.trains, item.trains);
            analysis.metrics = appendTable(analysis.metrics, item.metrics);
            analysis.issues = appendTable(analysis.issues, item.issues);
        catch ME
            analysis.issues = appendTable(analysis.issues, ...
                issueTable(recordingOpts.recordingId, "error", ME.message));
        end
    end
end

function accepted = acceptedRows(recordings)
    accepted = recordings;
    if height(recordings) == 0
        return;
    end
    if ismember("keep", recordings.Properties.VariableNames)
        accepted = recordings(logical(recordings.keep), :);
    elseif ismember("label", recordings.Properties.VariableNames)
        accepted = recordings(recordings.label == "good", :);
    elseif ismember("qcFlag", recordings.Properties.VariableNames)
        accepted = recordings(recordings.qcFlag == "accepted", :);
    end
end

function value = fieldOrDefault(S, fieldName, defaultValue)
    value = defaultValue;
    if isstruct(S) && isfield(S, fieldName)
        value = S.(fieldName);
    end
end

function recordings = recordingsTable(session)
    if isfield(session, "recordings") && istable(session.recordings)
        recordings = session.recordings;
    elseif isfield(session, "recordings") && isstruct(session.recordings)
        recordings = struct2table(session.recordings);
    else
        recordings = table();
    end

    if height(recordings) == 0
        recordings = table(strings(0, 1), strings(0, 1), strings(0, 1), ...
            strings(0, 1), ...
            'VariableNames', {'recordingId', 'filePath', 'label', 'comment'});
        return;
    end
    recordings.recordingId = string(recordings.recordingId);
    recordings.filePath = string(recordings.filePath);
    if ismember("label", recordings.Properties.VariableNames)
        recordings.label = normalizeLabel(recordings.label);
    else
        recordings.label = repmat("good", height(recordings), 1);
    end
    if ismember("comment", recordings.Properties.VariableNames)
        recordings.comment = string(recordings.comment);
    else
        recordings.comment = strings(height(recordings), 1);
    end
    if ismember("qcFlag", recordings.Properties.VariableNames)
        recordings.qcFlag = string(recordings.qcFlag);
    else
        recordings.qcFlag = repmat("accepted", height(recordings), 1);
    end
    if ismember("keep", recordings.Properties.VariableNames)
        recordings.keep = logical(recordings.keep);
    end
end

function labels = normalizeLabel(labels)
    labels = lower(strtrim(string(labels)));
    good = ismember(labels, ["good", "keep", "kept", "true", "1", "yes", "y"]);
    bad = ismember(labels, ["bad", "reject", "rejected", "false", "0", "no", "n"]);
    labels(good) = "good";
    labels(bad) = "bad";
end

function output = appendTable(output, input)
    if isempty(input) || height(input) == 0
        return;
    end
    if isempty(output) || width(output) == 0
        output = input;
    else
        output = [output; input];
    end
end

function issues = emptyIssues()
    issues = table(strings(0, 1), strings(0, 1), strings(0, 1), ...
        'VariableNames', {'recordingId', 'severity', 'message'});
end

function issues = issueTable(recordingId, severity, message)
    issues = table(string(recordingId), string(severity), string(message), ...
        'VariableNames', {'recordingId', 'severity', 'message'});
end
