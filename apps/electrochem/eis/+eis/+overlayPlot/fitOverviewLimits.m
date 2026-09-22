% App callback; requests a fresh data fit for all three overview axes.
function applicationState = fitOverviewLimits(applicationState, ~)
%FITOVERVIEWLIMITS Restore the Nyquist and Bode X/Y viewports together.
applicationState.session.cache.overviewViewRevision = ...
    applicationState.session.cache.overviewViewRevision + 1;
end
