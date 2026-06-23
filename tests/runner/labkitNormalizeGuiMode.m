function mode = labkitNormalizeGuiMode(value)
%LABKITNORMALIZEGUIMODE Normalize official GUI test visibility mode text.

    mode = lower(strtrim(string(value)));
    if ~isscalar(mode) || ~any(mode == ["hidden", "minimized", "visible"])
        error("LabKit:Tests:InvalidGuiMode", ...
            "GuiMode must be hidden, minimized, or visible.");
    end
end
