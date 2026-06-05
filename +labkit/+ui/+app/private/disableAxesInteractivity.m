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
