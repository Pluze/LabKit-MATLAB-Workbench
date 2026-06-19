% Expected caller: nerve_response_analysis.ops.analyzeRecording or tests.
% Input signalSet has timeSec, channelNames, values, and optional roles map.
% Output is pair-wise positive-minus-negative signals. No side effects.
function derived = computeDifferentials(signalSet, pairs)
%COMPUTEDIFFERENTIALS Build differential signals from configured pairs.

    timeSec = double(signalSet.timeSec(:));
    channelNames = string(signalSet.channelNames(:));
    values = double(signalSet.values);
    if size(values, 1) ~= numel(timeSec)
        error("nerve_response_analysis:DifferentialSizeMismatch", ...
            "signal values must be samples-by-channels.");
    end

    nPairs = numel(pairs);
    pairIds = strings(nPairs, 1);
    labels = strings(nPairs, 1);
    output = NaN(numel(timeSec), nPairs);
    status = strings(nPairs, 1);

    for k = 1:nPairs
        pairIds(k) = string(fieldOrDefault(pairs(k), "id", "pair" + k));
        labels(k) = string(fieldOrDefault(pairs(k), "label", pairIds(k)));
        positive = resolveTerminal(signalSet, fieldOrDefault(pairs(k), ...
            "positive", ""));
        negative = resolveTerminal(signalSet, fieldOrDefault(pairs(k), ...
            "negative", ""));
        posIdx = channelIndex(channelNames, positive);
        negIdx = channelIndex(channelNames, negative);
        if isempty(posIdx) || isempty(negIdx)
            status(k) = "missingChannel";
            continue;
        end
        output(:, k) = values(:, posIdx) - values(:, negIdx);
        status(k) = "ok";
    end

    derived = struct( ...
        "timeSec", timeSec, ...
        "pairIds", pairIds, ...
        "labels", labels, ...
        "values", output, ...
        "status", status);
end

function value = fieldOrDefault(S, fieldName, defaultValue)
    value = defaultValue;
    if isstruct(S) && isfield(S, fieldName)
        value = S.(fieldName);
    end
end

function channelName = resolveTerminal(signalSet, terminal)
    terminal = string(terminal);
    channelName = terminal;
    if isfield(signalSet, "roles") && isstruct(signalSet.roles) && ...
            isfield(signalSet.roles, char(terminal))
        role = signalSet.roles.(char(terminal));
        if isstruct(role) && isfield(role, "channelName")
            channelName = string(role.channelName);
        else
            channelName = string(role);
        end
    end
end

function idx = channelIndex(channelNames, requested)
    requested = normalizeName(requested);
    keys = normalizeName(channelNames);
    idx = find(keys == requested, 1);
end

function out = normalizeName(value)
    out = lower(regexprep(string(value), "[^A-Za-z0-9]", ""));
end
