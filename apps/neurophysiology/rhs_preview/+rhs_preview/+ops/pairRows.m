% Expected caller: rhs_preview.run and unit tests. Inputs are preview channel
% role rows plus an optional protocol struct. Output is editable differential
% or association rows for protocol drafting. No UI handles are touched.
function rows = pairRows(channelRows, protocol)
%PAIRROWS Build protocol pair rows from a loaded protocol or role names.

    if nargin < 1 || isempty(channelRows)
        channelRows = table();
    end
    if nargin < 2 || isempty(protocol)
        protocol = struct();
    end

    pairs = protocolPairs(protocol);
    if ~isempty(pairs)
        rows = rowsFromProtocolPairs(pairs);
        return;
    end

    rows = inferRowsFromRoles(channelRows);
end

function rows = rowsFromProtocolPairs(pairs)
    n = numel(pairs);
    id = strings(n, 1);
    label = strings(n, 1);
    positive = strings(n, 1);
    negative = strings(n, 1);
    mode = strings(n, 1);
    for k = 1:n
        id(k) = string(fieldOrDefault(pairs(k), "id", ""));
        label(k) = string(fieldOrDefault(pairs(k), "label", id(k)));
        positive(k) = string(fieldOrDefault(pairs(k), "positive", ""));
        negative(k) = string(fieldOrDefault(pairs(k), "negative", ""));
        mode(k) = string(fieldOrDefault(pairs(k), "mode", ...
            fieldOrDefault(pairs(k), "expression", "positive-minus-negative")));
    end
    rows = table(id, label, positive, negative, mode, ...
        'VariableNames', {'id', 'label', 'positive', 'negative', 'mode'});
end

function rows = inferRowsFromRoles(channelRows)
    rows = emptyRows();
    if ~istable(channelRows) || height(channelRows) == 0 || ...
            ~ismember("role", channelRows.Properties.VariableNames)
        return;
    end

    roleNames = unique(strtrim(string(channelRows.role)), "stable");
    roleNames = roleNames(strlength(roleNames) > 0);
    bases = eraseSuffix(roleNames(endsWith(roleNames, "_positive")), "_positive");
    id = strings(numel(bases), 1);
    label = strings(numel(bases), 1);
    positiveCol = strings(numel(bases), 1);
    negativeCol = strings(numel(bases), 1);
    mode = strings(numel(bases), 1);
    count = 0;
    for k = 1:numel(bases)
        base = bases(k);
        positive = base + "_positive";
        negative = base + "_negative";
        if ~any(roleNames == negative)
            continue;
        end
        count = count + 1;
        id(count) = base + "_diff";
        label(count) = upper(strrep(base, "_", " "));
        positiveCol(count) = positive;
        negativeCol(count) = negative;
        mode(count) = "positive-minus-negative";
    end
    if count == 0
        return;
    end
    rows = table(id(1:count), label(1:count), positiveCol(1:count), ...
        negativeCol(1:count), mode(1:count), ...
        'VariableNames', {'id', 'label', 'positive', 'negative', 'mode'});
end

function pairs = protocolPairs(protocol)
    pairs = struct([]);
    if isstruct(protocol) && isfield(protocol, "channels") && ...
            isfield(protocol.channels, "pairs")
        pairs = protocol.channels.pairs;
    end
end

function rows = emptyRows()
    rows = table(strings(0, 1), strings(0, 1), strings(0, 1), ...
        strings(0, 1), strings(0, 1), ...
        'VariableNames', {'id', 'label', 'positive', 'negative', 'mode'});
end

function out = eraseSuffix(values, suffix)
    out = regexprep(values, regexptranslate("escape", suffix) + "$", "");
end

function value = fieldOrDefault(S, fieldName, defaultValue)
    value = defaultValue;
    if isstruct(S) && isfield(S, fieldName)
        value = S.(fieldName);
    end
end
