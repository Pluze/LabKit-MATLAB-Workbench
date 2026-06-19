% Expected caller: rhs_preview.run and tests. Inputs are app state/channel
% rows. Output is a jsonencode-compatible channel protocol draft.
function payload = protocolJsonStruct(S)
%PROTOCOLJSONSTRUCT Build a protocol draft from Preview channel-role rows.

    rows = table();
    if isstruct(S) && isfield(S, "previewChannelRows") && ...
            istable(S.previewChannelRows)
        rows = S.previewChannelRows;
    end
    roles = roleStructArray(rows);
    base = baseIdentity(S);

    payload = struct( ...
        "schemaVersion", "labkit.rhs.protocol.v1", ...
        "protocolId", base.protocolId, ...
        "label", base.label, ...
        "channels", struct( ...
            "roles", roles));
end

function base = baseIdentity(S)
    base = struct( ...
        "protocolId", "rhs_channel_protocol", ...
        "label", "RHS Channel Protocol");
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
        roleCells{k} = struct( ...
            "id", string(roleId), ...
            "label", string(rows.label(r)), ...
            "nativeName", string(rows.channel(r)));
    end
    if ~isempty(roleCells)
        roles = [roleCells{:}];
    end
end

function value = fieldOrDefault(S, fieldName, defaultValue)
    value = defaultValue;
    if isstruct(S) && isfield(S, fieldName)
        value = S.(fieldName);
    end
end
