% Expected caller: rhs_preview.actions.table and unit tests. Inputs are one RHS info
% struct plus the current requested family/channel. Output is display-ready
% dropdown options and the normalized readable channel choice.
function selection = channelSelection(info, currentFamily, currentChannel)
%CHANNELSELECTION Build Preview channel dropdown state from RHS metadata.

    if nargin < 2 || isempty(currentFamily)
        currentFamily = "amplifier";
    end
    if nargin < 3 || isempty(currentChannel)
        currentChannel = "";
    end

    families = availableFamilies(info);
    if isempty(families)
        selection = struct( ...
            "families", "amplifier", ...
            "family", "amplifier", ...
            "channels", "Choose RHS first", ...
            "channelName", "Choose RHS first", ...
            "actualChannelName", "", ...
            "hasChannels", false);
        return;
    end

    family = string(currentFamily);
    if ~any(families == family)
        family = families(1);
    end

    channels = channelNamesForFamily(info, family);
    actualChannelName = string(currentChannel);
    if isempty(channels)
        channelName = "No channels available";
        actualChannelName = "";
    else
        if ~any(channels == actualChannelName)
            actualChannelName = channels(1);
        end
        channelName = actualChannelName;
    end

    selection = struct( ...
        "families", families, ...
        "family", family, ...
        "channels", channelsOrPrompt(channels), ...
        "channelName", channelName, ...
        "actualChannelName", actualChannelName, ...
        "hasChannels", ~isempty(channels));
end

function families = availableFamilies(info)
    candidates = ["amplifier"; "stim"; "dcAmplifier"; "boardAdc"; ...
        "boardDac"; "boardDigIn"; "boardDigOut"];
    keep = false(size(candidates));
    for k = 1:numel(candidates)
        keep(k) = ~isempty(channelNamesForFamily(info, candidates(k)));
    end
    families = candidates(keep);
end

function names = channelNamesForFamily(info, family)
    names = strings(0, 1);
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

    if ~isfield(info.channelFamilies, familyKey)
        return;
    end
    channels = info.channelFamilies.(familyKey);
    if isempty(channels)
        return;
    end
    names = string({channels.nativeName}).';
end

function channels = channelsOrPrompt(channels)
    if isempty(channels)
        channels = "No channels available";
    end
end
