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
