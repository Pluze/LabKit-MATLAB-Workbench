% Expected caller: nerve_response_analysis.analysisRun.analyzeSession or tests.
% Inputs are one RHS path, one protocol struct, and options. Output is a
% recording analysis struct. Side effects are lazy RHS window reads only.
function analysis = analyzeRecording(filepath, protocol, opts)
%ANALYZERECORDING Analyze one RHS recording according to a protocol.

    if nargin < 2 || isempty(protocol)
        protocol = struct();
    end
    if nargin < 3 || isempty(opts)
        opts = struct();
    end

    filepath = string(filepath);
    recordingId = string(fieldOrDefault(opts, "recordingId", ""));
    [index, status] = labkit.rhs.indexFile(filepath);

    analysis = emptyAnalysis(recordingId, filepath, protocol);
    if ~status.ok
        analysis.issues = issueTable(recordingId, "error", status.message);
        return;
    end

    maxDurationSec = double(fieldOrDefault(opts, "maxDurationSec", Inf));
    if ~isfinite(maxDurationSec) || maxDurationSec <= 0
        maxDurationSec = index.durationSec;
    end
    maxDurationSec = min(maxDurationSec, index.durationSec);

    roles = resolveRoles(index.info, protocol);
    [eventTime, eventSignal, sourceId, sourceIssue] = selectEventSource( ...
        filepath, index, roles, protocol, maxDurationSec);
    if strlength(sourceIssue) > 0
        analysis.issues = [analysis.issues; issueTable(recordingId, ...
            "warning", sourceIssue)];
    end
    if isempty(eventTime)
        return;
    end

    eventOpts = fieldOrDefault(opts, "eventDetection", struct());
    eventOpts.sourceId = sourceId;
    [events, trains] = nerve_response_analysis.analysisRun.detectEventTrains( ...
        eventTime, eventSignal, eventOpts);
    analysis.events = addRecordingId(events, recordingId);
    analysis.trains = addRecordingId(trains, recordingId);
    if height(events) == 0
        analysis.issues = [analysis.issues; issueTable(recordingId, ...
            "warning", "No event train was detected.")];
        return;
    end

    pairs = analysisPairs(protocol, roles);
    metricsByPair = cell(numel(pairs), 1);
    issuesByPair = cell(numel(pairs), 1);
    for k = 1:numel(pairs)
        pairResult = analyzePair(filepath, pairs(k), roles, protocol, ...
            maxDurationSec, events.timeSec, recordingId);
        metricsByPair{k} = pairResult.metrics;
        issuesByPair{k} = pairResult.issues;
    end
    analysis.metrics = appendTables(analysis.metrics, metricsByPair);
    analysis.issues = appendTables(analysis.issues, issuesByPair);
end

function analysis = emptyAnalysis(recordingId, filepath, protocol)
    analysis = struct( ...
        "type", "nerveResponseRecordingAnalysis", ...
        "version", 1, ...
        "recordingId", recordingId, ...
        "filepath", filepath, ...
        "protocolSnapshot", protocol, ...
        "events", table(), ...
        "trains", table(), ...
        "metrics", emptyMetrics(), ...
        "issues", emptyIssues());
end

function value = fieldOrDefault(S, fieldName, defaultValue)
    value = defaultValue;
    if isstruct(S) && isfield(S, fieldName)
        value = S.(fieldName);
    end
end

function roles = resolveRoles(info, protocol)
    roles = struct();
    channels = info.channelFamilies.amplifier;
    roleSpecs = struct([]);
    if isfield(protocol, "channels") && isfield(protocol.channels, "roles")
        roleSpecs = protocol.channels.roles;
    end
    for k = 1:numel(roleSpecs)
        roleId = string(fieldOrDefault(roleSpecs(k), "id", "role" + k));
        aliases = roleAliases(roleSpecs(k));
        [channelName, found] = findChannel(channels, aliases);
        key = matlab.lang.makeValidName(char(roleId));
        roles.(key) = struct( ...
            "id", roleId, ...
            "label", string(fieldOrDefault(roleSpecs(k), "label", roleId)), ...
            "channelName", channelName, ...
            "found", found);
    end
end

function aliases = roleAliases(roleSpec)
    aliases = string(fieldOrDefault(roleSpec, "id", ""));
    if isfield(roleSpec, "nativeName")
        aliases = [aliases(:); string(roleSpec.nativeName(:))];
    end
    if isfield(roleSpec, "match") && isfield(roleSpec.match, "anyNativeName")
        aliases = [aliases(:); string(roleSpec.match.anyNativeName(:))];
    end
end

function [channelName, found] = findChannel(channels, aliases)
    native = string({channels.nativeName}).';
    custom = string({channels.customName}).';
    keys = [normalizeName(native), normalizeName(custom)];
    aliases = normalizeName(aliases);
    found = false;
    channelName = "";
    for k = 1:numel(aliases)
        idx = find(keys(:, 1) == aliases(k) | keys(:, 2) == aliases(k), 1);
        if ~isempty(idx)
            channelName = native(idx);
            found = true;
            return;
        end
    end
end

function [timeSec, signal, sourceId, issue] = selectEventSource(filepath, ...
        index, roles, protocol, maxDurationSec)
    timeSec = [];
    signal = [];
    sourceId = "none";
    issue = "";
    readRange = [0 maxDurationSec];

    [stimWindow, stimStatus] = labkit.rhs.readWindow(filepath, ...
        struct("family", "stim", "timeRangeSec", readRange));
    if stimStatus.ok && ~isempty(stimWindow.values) && ...
            any(abs(stimWindow.values(:)) > 0)
        timeSec = stimWindow.timeSec;
        signal = max(abs(stimWindow.values), [], 2);
        sourceId = "rhs_stim_current";
        return;
    end

    refName = roleChannel(roles, "reference");
    if strlength(refName) > 0
        [timeSec, signal, ok] = readAmplifier(filepath, refName, readRange);
        if ok
            sourceId = "reference_derivative";
            return;
        end
    end

    roleNames = fallbackRoleNames(protocol);
    for k = 1:numel(roleNames)
        fallbackName = roleChannel(roles, roleNames(k));
        if strlength(fallbackName) == 0
            continue;
        end
        [timeSec, signal, ok] = readAmplifier(filepath, fallbackName, readRange);
        if ok
            sourceId = "recording_derivative_fallback";
            issue = "Reference event source was unavailable; used recording fallback.";
            return;
        end
    end

    channels = index.info.channelFamilies.amplifier;
    if ~isempty(channels)
        [timeSec, signal, ok] = readAmplifier(filepath, string(channels(1).nativeName), ...
            readRange);
        if ok
            sourceId = "recording_derivative_fallback";
            issue = "Protocol roles were unavailable; used first amplifier channel.";
            return;
        end
    end

    issue = "No usable event source channel was found.";
end

function names = fallbackRoleNames(protocol)
    names = strings(0, 1);
    pairNames = protocolPairRoleNames(protocol);
    if ~isempty(pairNames)
        names = pairNames;
    end
    if isempty(names)
        names = ["cp_positive"; "cp_negative"; "ta_positive"; ...
            "ta_negative"; "s_positive"; "s_negative"];
    end
end

function names = protocolPairRoleNames(protocol)
    names = strings(0, 1);
    if ~isstruct(protocol) || ~isfield(protocol, "channels") || ...
            ~isfield(protocol.channels, "pairs")
        return;
    end
    pairs = protocol.channels.pairs;
    collected = strings(2 * numel(pairs), 1);
    count = 0;
    for k = 1:numel(pairs)
        if isfield(pairs(k), "positive")
            count = count + 1;
            collected(count) = string(pairs(k).positive);
        end
        if isfield(pairs(k), "negative")
            count = count + 1;
            collected(count) = string(pairs(k).negative);
        end
    end
    if count > 0
        names = unique(collected(1:count), "stable");
    end
end

function pairs = analysisPairs(protocol, roles)
    pairs = configuredPairs(protocol);
    if ~isempty(pairs)
        return;
    end
    pairs = inferredPairs(roles);
end

function pairs = configuredPairs(protocol)
    pairs = struct([]);
    if isfield(protocol, "channels") && isfield(protocol.channels, "pairs")
        pairs = protocol.channels.pairs;
    end
end

function pairs = inferredPairs(roles)
    pairs = struct([]);
    if ~isstruct(roles)
        return;
    end
    names = string(fieldnames(roles));
    pairCells = {};
    for k = 1:numel(names)
        role = roles.(char(names(k)));
        roleId = string(fieldOrDefault(role, "id", names(k)));
        if ~endsWith(roleId, "_positive")
            continue;
        end
        negativeId = replace(roleId, "_positive", "_negative");
        negativeKey = matlab.lang.makeValidName(char(negativeId));
        if ~isfield(roles, char(negativeKey))
            continue;
        end
        negative = roles.(char(negativeKey));
        if ~logical(fieldOrDefault(role, "found", false)) || ...
                ~logical(fieldOrDefault(negative, "found", false))
            continue;
        end
        baseId = extractBefore(roleId, strlength(roleId) - strlength("_positive") + 1);
        if strlength(baseId) == 0
            baseId = "pair";
        end
        pairCells{end + 1} = struct( ...
            "id", baseId + "_diff", ...
            "label", upper(baseId), ...
            "positive", roleId, ...
            "negative", negativeId, ...
            "mode", "positive-minus-negative");
    end
    if ~isempty(pairCells)
        pairs = [pairCells{:}];
    end
end

function result = analyzePair(filepath, pair, roles, protocol, ...
        maxDurationSec, eventTimesSec, recordingId)
    result = struct("metrics", emptyMetrics(), "issues", emptyIssues());
    pairId = string(fieldOrDefault(pair, "id", "pair"));
    label = string(fieldOrDefault(pair, "label", pairId));
    positiveName = roleChannel(roles, string(fieldOrDefault(pair, "positive", "")));
    negativeName = roleChannel(roles, string(fieldOrDefault(pair, "negative", "")));
    if strlength(positiveName) == 0 || strlength(negativeName) == 0
        result.issues = issueTable(recordingId, "warning", ...
            "Skipped " + pairId + " because one configured channel was missing.");
        return;
    end

    readRange = [0 maxDurationSec];
    [timeSec, positive, okPositive] = readAmplifier(filepath, positiveName, readRange);
    [~, negative, okNegative] = readAmplifier(filepath, negativeName, readRange);
    if ~(okPositive && okNegative)
        result.issues = issueTable(recordingId, "warning", ...
            "Skipped " + pairId + " because waveform read failed.");
        return;
    end

    common = [];
    referenceName = roleChannel(roles, "reference");
    if strlength(referenceName) > 0
        [~, common, okCommon] = readAmplifier(filepath, referenceName, readRange);
        if ~okCommon
            common = [];
        end
    end

    commonOpts = struct();
    corrected = nerve_response_analysis.analysisRun.commonModeCorrect(timeSec, ...
        positive, negative, common, commonOpts);
    metrics = nerve_response_analysis.analysisRun.measureCapMetrics(timeSec, ...
        corrected.corrected, eventTimesSec, struct());
    metrics.recordingId = repmat(recordingId, height(metrics), 1);
    metrics.pairId = repmat(pairId, height(metrics), 1);
    metrics.pairLabel = repmat(label, height(metrics), 1);
    if height(metrics) > 0
        metrics = movevars(metrics, ["recordingId", "pairId", "pairLabel"], ...
            "Before", 1);
    end
    result.metrics = metrics;
end

function [timeSec, values, ok] = readAmplifier(filepath, channelName, readRange)
    [window, status] = labkit.rhs.readWindow(filepath, struct( ...
        "family", "amplifier", ...
        "channels", channelName, ...
        "timeRangeSec", readRange));
    ok = status.ok && ~isempty(window.values);
    timeSec = [];
    values = [];
    if ok
        timeSec = window.timeSec;
        values = window.values(:, 1);
    end
end

function channelName = roleChannel(roles, roleId)
    key = matlab.lang.makeValidName(char(string(roleId)));
    channelName = "";
    if isstruct(roles) && isfield(roles, key) && roles.(key).found
        channelName = string(roles.(key).channelName);
    end
end

function out = normalizeName(value)
    out = lower(regexprep(string(value), "[^A-Za-z0-9]", ""));
end

function T = addRecordingId(T, recordingId)
    if isempty(T) || height(T) == 0
        return;
    end
    T.recordingId = repmat(recordingId, height(T), 1);
    T = movevars(T, "recordingId", "Before", 1);
end

function output = appendTables(output, tables)
    for k = 1:numel(tables)
        input = tables{k};
        if isempty(input) || height(input) == 0
            continue;
        end
        if isempty(output) || width(output) == 0
            output = input;
        else
            output = [output; input];
        end
    end
end

function metrics = emptyMetrics()
    metrics = table(strings(0, 1), strings(0, 1), strings(0, 1), ...
        zeros(0, 1), zeros(0, 1), zeros(0, 1), zeros(0, 1), ...
        zeros(0, 1), zeros(0, 1), zeros(0, 1), zeros(0, 1), ...
        zeros(0, 1), zeros(0, 1), strings(0, 1), ...
        'VariableNames', {'recordingId', 'pairId', 'pairLabel', ...
        'eventIndex', 'stimTimeSec', 'baselineMean', 'noiseRms', ...
        'peakPositive', 'peakNegative', 'peakToPeak', 'peakTimeSec', ...
        'latencySec', 'snrDb', 'status'});
end

function issues = emptyIssues()
    issues = table(strings(0, 1), strings(0, 1), strings(0, 1), ...
        'VariableNames', {'recordingId', 'severity', 'message'});
end

function issues = issueTable(recordingId, severity, message)
    issues = table(string(recordingId), string(severity), string(message), ...
        'VariableNames', {'recordingId', 'severity', 'message'});
end
