% Private UI app helper. Expected caller: labkit.ui.app shell construction
% code. Inputs and outputs are internal uifigure, grid, tab, or resize handle
% values. Side effects are limited to UI object creation or callback wiring on
% supplied parents; assumes the caller owns component lifecycle.
function disableAxesInteractivity(ax)
%DISABLEAXESINTERACTIVITY Disable optional axes interactions when available.
%
% Called by:
%   UI axes/image helpers when an app wants static preview axes.
%
% Inputs:
%   ax - MATLAB axes or UIAxes handle.
%
% Side effects:
%   Best-effort removal of default interactivity, Interactions entries, and
%   toolbar visibility. Unsupported properties are ignored for MATLAB-version
%   compatibility.

    try
        disableDefaultInteractivity(ax);
    catch
    end
    try
        ax.Interactions = [];
    catch
    end
    try
        ax.Toolbar.Visible = 'off';
    catch
    end
end
