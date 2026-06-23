function cleanup = labkitGuiTestMode(guiMode)
%LABKITGUITESTMODE Apply GUI window visibility policy for official tests.
%
% Inputs:
%   guiMode - "hidden", "minimized", or "visible".
%
% Output:
%   cleanup - onCleanup object that restores LABKIT_GUI_TEST_MODE and
%       DefaultFigureVisible.

    mode = labkitNormalizeGuiMode(guiMode);
    previousGuiMode = getenv("LABKIT_GUI_TEST_MODE");
    previousVisible = get(groot, "DefaultFigureVisible");
    setenv("LABKIT_GUI_TEST_MODE", char(mode));
    if mode == "hidden"
        set(groot, "DefaultFigureVisible", "off");
    else
        set(groot, "DefaultFigureVisible", "on");
    end
    cleanup = onCleanup(@() restoreGuiMode(previousGuiMode, previousVisible));
end

function restoreGuiMode(previousGuiMode, previousVisible)
    setenv("LABKIT_GUI_TEST_MODE", previousGuiMode);
    set(groot, "DefaultFigureVisible", previousVisible);
end
