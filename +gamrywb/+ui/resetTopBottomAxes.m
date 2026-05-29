function resetTopBottomAxes(topAxes, bottomAxes, resetScaleAndTicks)
%RESETTOPBOTTOMAXES Reset shared top/bottom app axes to their empty titles.

    if nargin < 3
        resetScaleAndTicks = false;
    end

    gamrywb.ui.hardResetAxis(topAxes, 'Top Plot', resetScaleAndTicks);
    gamrywb.ui.hardResetAxis(bottomAxes, 'Bottom Plot', resetScaleAndTicks);
end
