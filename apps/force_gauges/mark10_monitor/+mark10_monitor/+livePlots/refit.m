function state = refit(state, ~)
%REFIT Request fresh X and independent Y limits for both monitor plots.
state = mark10_monitor.livePlots.updateLimits(state, true);
end
