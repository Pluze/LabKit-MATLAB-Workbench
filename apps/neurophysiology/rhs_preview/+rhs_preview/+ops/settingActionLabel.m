% Expected caller: rhs_preview.run. Input is a changed control id. Output is
% user-facing action text for state/log summaries.
function label = settingActionLabel(changedId)
%SETTINGACTIONLABEL Label preview-setting changes.

    if string(changedId) == "windowStartPanner"
        label = "Panned preview window";
    else
        label = "Updated preview window";
    end
end
