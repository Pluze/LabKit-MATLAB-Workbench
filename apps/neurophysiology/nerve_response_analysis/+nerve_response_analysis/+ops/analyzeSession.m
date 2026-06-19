% Expected caller: nerve_response_analysis.run or tests. Input is a
% rhs_screen session struct plus protocol and options. Output is a combined
% analysis struct. Side effects are lazy RHS reads through analyzeRecording.
function analysis = analyzeSession(session, protocol, opts)
%ANALYZESESSION Analyze accepted recordings from a screening session.

    if nargin < 2 || isempty(protocol)
        protocol = struct();
    end
    if nargin < 3 || isempty(opts)
        opts = struct();
    end

    recordings = recordingsTable(session);
    accepted = recordings;
    if height(recordings) > 0 && ismember("keep", recordings.Properties.VariableNames)
        accepted = recordings(logical(recordings.keep), :);
    elseif height(recordings) > 0 && ismember("qcFlag", recordings.Properties.VariableNames)
        accepted = recordings(recordings.qcFlag == "accepted", :);
    end

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
            item = nerve_response_analysis.ops.analyzeRecording( ...
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
            'VariableNames', {'recordingId', 'filePath', 'qcFlag'});
        return;
    end
    recordings.recordingId = string(recordings.recordingId);
    recordings.filePath = string(recordings.filePath);
    if ismember("qcFlag", recordings.Properties.VariableNames)
        recordings.qcFlag = string(recordings.qcFlag);
    else
        recordings.qcFlag = repmat("accepted", height(recordings), 1);
    end
    if ismember("keep", recordings.Properties.VariableNames)
        recordings.keep = logical(recordings.keep);
    end
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
