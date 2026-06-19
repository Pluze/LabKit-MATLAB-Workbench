% Expected caller: rhs_preview.run and tests. Inputs are app state/channel
% rows. Output is a jsonencode-compatible protocol draft without local raw
% file paths.
function payload = protocolJsonStruct(S)
%PROTOCOLJSONSTRUCT Build a protocol draft from Preview channel-role rows.

    rows = table();
    if isstruct(S) && isfield(S, "previewChannelRows") && ...
            istable(S.previewChannelRows)
        rows = S.previewChannelRows;
    end
    roles = roleStructArray(rows);
    pairs = pairStructArray(pairRowsFromState(S));
    family = string(fieldOrDefault(S, "family", "amplifier"));
    windowStart = double(fieldOrDefault(S, "windowStartSec", 0));
    windowDuration = double(fieldOrDefault(S, "windowDurationSec", 0.050));
    base = baseIdentity(S);

    payload = struct( ...
        "schemaVersion", "labkit.rhs.protocol.v1", ...
        "protocolId", base.protocolId, ...
        "label", base.label, ...
        "channels", struct( ...
            "roles", roles, ...
            "pairs", pairs), ...
        "preview", struct( ...
            "defaultFamily", family, ...
            "defaultWindowSec", [windowStart, windowStart + windowDuration]));
end

function base = baseIdentity(S)
    base = struct( ...
        "protocolId", "rhs_protocol_draft", ...
        "label", "RHS Protocol Draft");
    if isstruct(S) && isfield(S, "protocol") && isstruct(S.protocol) && ...
            isscalar(S.protocol)
        if isfield(S.protocol, "protocolId")
            base.protocolId = string(S.protocol.protocolId);
        end
        if isfield(S.protocol, "label")
            base.label = string(S.protocol.label);
        end
    end
end

function roles = roleStructArray(rows)
    roles = struct([]);
    if height(rows) == 0
        return;
    end
    keep = strlength(strtrim(string(rows.role))) > 0;
    idx = find(keep);
    roleCells = cell(numel(idx), 1);
    for k = 1:numel(idx)
        r = idx(k);
        roleId = matlab.lang.makeValidName(char(rows.role(r)));
        match = struct();
        match.anyNativeName = cellstr(string(rows.channel(r)));
        roleCells{k} = struct( ...
            "id", string(roleId), ...
            "label", string(rows.label(r)), ...
            "match", match, ...
            "required", logical(rows.required(r)));
    end
    if ~isempty(roleCells)
        roles = [roleCells{:}];
    end
end

function rows = pairRowsFromState(S)
    rows = table();
    if isstruct(S) && isfield(S, "protocolPairRows") && ...
            istable(S.protocolPairRows)
        rows = S.protocolPairRows;
    end
end

function pairs = pairStructArray(rows)
    pairs = struct([]);
    if height(rows) == 0
        return;
    end
    keep = strlength(strtrim(string(rows.id))) > 0 & ...
        strlength(strtrim(string(rows.positive))) > 0 & ...
        strlength(strtrim(string(rows.negative))) > 0;
    idx = find(keep);
    pairCells = cell(numel(idx), 1);
    for k = 1:numel(idx)
        r = idx(k);
        pairCells{k} = struct( ...
            "id", string(rows.id(r)), ...
            "label", string(rows.label(r)), ...
            "positive", string(rows.positive(r)), ...
            "negative", string(rows.negative(r)), ...
            "mode", string(rows.mode(r)));
    end
    if ~isempty(pairCells)
        pairs = [pairCells{:}];
    end
end

function value = fieldOrDefault(S, fieldName, defaultValue)
    value = defaultValue;
    if isstruct(S) && isfield(S, fieldName)
        value = S.(fieldName);
    end
end
