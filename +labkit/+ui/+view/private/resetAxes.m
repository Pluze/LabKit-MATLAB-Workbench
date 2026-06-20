% Private UI view helper. Expected caller: labkit.ui.view panel, control,
% plot, or text facades. Inputs and outputs are internal UI handles, labels,
% selections, table data, or plot info. Side effects are limited to supplied UI
% parents or axes; assumes the caller owns callbacks and app state.
function resetAxes(ax, ttl, resetScaleAndTicks)
%HARDRESETAXIS Reset an app axes to an empty titled state.
%
% Inputs:
%   ax - target axes.
%   ttl - title text.
%   resetScaleAndTicks - optional logical, default false. True resets
%                        linear scales and automatic ticks.
%
% Output:
%   Mutates ax in place and re-enables standard axes popout.

    if nargin < 3
        resetScaleAndTicks = false;
    end

    cla(ax, 'reset');
    clearImageViewState(ax);
    ax.NextPlot = 'replace';
    ax.XLimMode = 'auto';
    ax.YLimMode = 'auto';
    if resetScaleAndTicks
        ax.XScale = 'linear';
        ax.YScale = 'linear';
        ax.XTickMode = 'auto';
        ax.YTickMode = 'auto';
    end
    title(ax, ttl);
    xlabel(ax, '');
    ylabel(ax, '');
    grid(ax, 'off');
    box(ax, 'on');
    enablePopout(ax);
end

function clearImageViewState(ax)
    key = 'labkitImageViewBounds';
    if isappdata(ax, key)
        rmappdata(ax, key);
    end
end
