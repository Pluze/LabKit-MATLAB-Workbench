function disableAxesInteractivity(ax)
%DISABLEAXESINTERACTIVITY Disable optional axes interactions when available.

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
