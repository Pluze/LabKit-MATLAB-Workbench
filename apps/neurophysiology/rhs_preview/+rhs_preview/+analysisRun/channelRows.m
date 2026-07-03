% Expected caller: rhs_preview.definitionActions and unit tests. Inputs are one RHS info
% struct, a channel family, maximum default preview count, and optional
% protocol struct. Output is a table used by the Preview channel selector.
function rows = channelRows(info, family, maxPreviewChannels, protocol)
%CHANNELROWS Build editable channel rows from RHS metadata.

    if nargin < 2 || isempty(family)
        family = "amplifier";
    end
    if nargin < 3 || isempty(maxPreviewChannels)
        maxPreviewChannels = 8;
    end
    if nargin < 4 || isempty(protocol)
        protocol = struct();
    end

    channels = channelsForFamily(info, family);
    family = string(family);
    maxPreviewChannels = max(0, floor(double(maxPreviewChannels)));
    n = numel(channels);

    preview = false(n, 1);
    preview(1:min(n, maxPreviewChannels)) = true;
    role = strings(n, 1);
    label = strings(n, 1);
    channel = strings(n, 1);
    unit = repmat(unitForFamily(family), n, 1);
    familyColumn = repmat(family, n, 1);

    roles = protocolRoles(protocol);
    for k = 1:n
        channel(k) = string(channels(k).nativeName);
        [role(k), label(k)] = roleForChannel(roles, channel(k));
        if strlength(label(k)) == 0
            label(k) = channel(k);
        end
    end

    rows = table(preview, role, label, familyColumn, channel, unit, ...
        'VariableNames', {'preview', 'role', 'label', 'family', 'channel', ...
        'unit'});
end

function channels = channelsForFamily(info, family)
    channels = emptyChannelStruct();
    if ~isstruct(info) || ~isfield(info, "channelFamilies")
        return;
    end

    family = string(family);
    switch family
        case {"amplifier", "stim"}
            familyKey = "amplifier";
        case "dcAmplifier"
            if ~isfield(info, "dcAmplifierSaved") || ~logical(info.dcAmplifierSaved)
                return;
            end
            familyKey = "amplifier";
        case "boardAdc"
            familyKey = "boardAdc";
        case "boardDac"
            familyKey = "boardDac";
        case "boardDigIn"
            familyKey = "boardDigIn";
        case "boardDigOut"
            familyKey = "boardDigOut";
        otherwise
            return;
    end
    if isfield(info.channelFamilies, familyKey)
        channels = info.channelFamilies.(familyKey);
    end
end

function channels = emptyChannelStruct()
    channels = struct("nativeName", {}, "customName", {});
end

function unit = unitForFamily(family)
    switch string(family)
        case "amplifier"
            unit = "microvolts";
        case "stim"
            unit = "microamps";
        case {"dcAmplifier", "boardAdc", "boardDac"}
            unit = "volts";
        otherwise
            unit = "logical";
    end
end

function roles = protocolRoles(protocol)
    roles = struct([]);
    if isstruct(protocol) && isfield(protocol, "channels") && ...
            isfield(protocol.channels, "roles")
        roles = protocol.channels.roles;
    end
end

function [roleId, roleLabel] = roleForChannel(roles, channelName)
    roleId = "";
    roleLabel = "";
    normalizedChannel = normalizeName(channelName);
    for k = 1:numel(roles)
        aliases = roleAliases(roles(k));
        if any(normalizeName(aliases) == normalizedChannel)
            roleId = string(fieldOrDefault(roles(k), "id", ""));
            roleLabel = string(fieldOrDefault(roles(k), "label", roleId));
            return;
        end
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

function value = fieldOrDefault(S, fieldName, defaultValue)
    value = defaultValue;
    if isstruct(S) && isfield(S, fieldName)
        value = S.(fieldName);
    end
end

function out = normalizeName(value)
    out = lower(regexprep(string(value), "[^A-Za-z0-9]", ""));
end
