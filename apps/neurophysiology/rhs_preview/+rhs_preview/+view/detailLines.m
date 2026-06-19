% Expected caller: rhs_preview.run and rhs_preview.ui.buildSpec. Input is
% the app state struct. Output is a cell array of display lines for a status
% panel. No UI handles or app state are mutated.
function lines = detailLines(S)
%DETAILLINES Build RHS preview detail lines for display.

    S = normalizeState(S);
    lines = { ...
        char("RHS file: " + displayFile(S.rhsFile)); ...
        char("Protocol: " + displayFile(S.protocolFile)); ...
        char("Status: " + string(S.statusMessage)); ...
        char("Preview family: " + string(S.family)); ...
        char("Selected channels: " + selectedChannelsText(S)); ...
        char("Protocol pairs: " + protocolPairsText(S)); ...
        char("Window: " + sprintf("%.6g", S.windowStartSec) + " s + " + ...
        sprintf("%.6g", S.windowDurationSec) + " s"); ...
        char("ROI: " + roiText(S)); ...
        char("Channels: " + channelNamesText(S.info)); ...
        char("Last action: " + string(S.lastAction))};
end

function S = normalizeState(S)
    if ~isstruct(S)
        S = struct();
    end
    defaults = struct( ...
        "rhsFile", "", ...
        "protocolFile", "", ...
        "family", "amplifier", ...
        "previewChannelRows", table(), ...
        "protocolPairRows", table(), ...
        "windowStartSec", 0, ...
        "windowDurationSec", 0.050, ...
        "roiSec", [NaN NaN], ...
        "info", [], ...
        "statusMessage", "No RHS file selected.", ...
        "lastAction", "Ready");
    names = fieldnames(defaults);
    for k = 1:numel(names)
        if ~isfield(S, names{k})
            S.(names{k}) = defaults.(names{k});
        end
    end
end

function text = protocolPairsText(S)
    text = "none";
    if ~isfield(S, "protocolPairRows") || ~istable(S.protocolPairRows) || ...
            height(S.protocolPairRows) == 0
        return;
    end
    rows = S.protocolPairRows;
    names = string(rows.id(:)).';
    names = names(strlength(names) > 0);
    if isempty(names)
        return;
    end
    if numel(names) > 8
        names = [names(1:8), "..."];
    end
    text = string(sprintf("%d (%s)", numel(names), char(strjoin(names, ", "))));
end

function text = roiText(S)
    roiSec = double(S.roiSec);
    if numel(roiSec) ~= 2 || any(~isfinite(roiSec)) || diff(roiSec) <= 0
        text = "none";
    else
        text = string(sprintf("%.6g to %.6g s", roiSec(1), roiSec(2)));
    end
end

function text = displayFile(filepath)
    filepath = string(filepath);
    if strlength(filepath) == 0
        text = "none";
        return;
    end
    [~, name, ext] = fileparts(char(filepath));
    text = string([name ext]);
end

function text = channelNamesText(info)
    text = "n/a";
    if ~isstruct(info) || ~isfield(info, "channelFamilies")
        return;
    end
    channels = info.channelFamilies.amplifier;
    if isempty(channels)
        text = "none";
        return;
    end
    names = string({channels.nativeName});
    if numel(names) > 8
        names = [names(1:8), "..."];
    end
    text = strjoin(names, ", ");
end

function text = selectedChannelsText(S)
    text = "none";
    if ~isfield(S, "previewChannelRows") || ~istable(S.previewChannelRows) || ...
            height(S.previewChannelRows) == 0
        return;
    end
    rows = S.previewChannelRows(logical(S.previewChannelRows.preview), :);
    if height(rows) == 0
        return;
    end
    names = string(rows.channel(:)).';
    if numel(names) > 8
        names = [names(1:8), "..."];
    end
    text = string(sprintf("%d (%s)", height(rows), char(strjoin(names, ", "))));
end
