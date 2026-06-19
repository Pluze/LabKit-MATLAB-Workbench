% Expected caller: rhs_preview.run. Input/output is app state. The selected
% family is normalized to a family available in the current RHS info.
function S = normalizeChannelSelection(S)
%NORMALIZECHANNELSELECTION Keep selected family valid for available channels.

    selection = rhs_preview.view.channelSelection(S.info, S.family, "");
    S.family = selection.family;
end
